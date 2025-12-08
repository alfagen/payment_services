# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

module PaymentServices
  class Bovapay
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
      Error = Class.new StandardError

      def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
        make_payout(
          amount: amount,
          destination_account: destination_account,
          order_payout_id: order_payout_id
        )
      end

      def refresh_status!(payout_id)
        payout = Payout.find(payout_id)
        return if payout.pending?

        transaction = client.payout(withdrawal_id: payout.withdrawal_id)
        payout.update_state_by_provider(transaction.dig('payload', 'state'))
        transaction
      end

      private

      delegate :sbp_bank, :sbp?, to: :bank_resolver

      attr_reader :payout

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
        response = client.create_payout(params: payout_params)
        raise Error, "Can't create invoice: #{response['errors']}" if response['errors'].present?

        payout.pay!(withdrawal_id: response.dig('payload', 'id'))
      end

      def payout_params
        order = OrderPayout.find(payout.order_payout_id).order
        params = {
          to_card: payout.destination_account,
          amount: payout.amount.to_i,
          callback_url: "#{Rails.application.routes.url_helpers.public_public_callbacks_api_root_url}/v1/appex_money/confirm_payout",
          merchant_id: "#{order.public_id}-#{payout.order_payout_id}",
          currency: payout.amount_currency.to_s.downcase,
          payment_method: sbp? ? 'sbp' : 'card',
          lifetime: 3600
        }
        params[:sbp_bank_name] = sbp_bank if sbp?
        params
      end

      def bank_resolver
        @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
