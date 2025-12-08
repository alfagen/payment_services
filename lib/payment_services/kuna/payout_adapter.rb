# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

module PaymentServices
  class Kuna
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
      DEFAULT_GATEWAY = 'default'

      def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
        make_payout(
          amount: amount,
          destination_account: destination_account,
          order_payout_id: order_payout_id
        )
      end

      def refresh_status!(payout_id)
        @payout_id = payout_id
        return if payout.pending?

        response = client.payout_status(params: { id: payout.withdrawal_id })

        raise "Can't get withdrawal details: #{response['messages']}" if response['messages']

        payout.update!(provider_state: response['status']) if response['status']
        payout.confirm! if payout.success?
        payout.fail! if payout.status_failed?

        response
      end

      def payout
        @payout ||= Payout.find_by(id: payout_id)
      end

      private

      attr_accessor :payout_id

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout_id = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id).id

        params = {
          amount: amount.to_d,
          withdraw_type: currency,
          withdraw_to: destination_account,
          gateway: gateway
        }
        response = client.create_payout(params: params)
        # NOTE: API returns an array of responses
        response = response.first if response.is_a? Array

        raise "Can't process payout: #{response['messages']}" if response['messages']

        payout.pay!(withdrawal_id: response['withdrawal_id']) if response['withdrawal_id']
      end

      def client
        @client ||= begin
          Client.new(api_key: api_key, secret_key: api_secret)
        end
      end

      def gateway
        return DEFAULT_GATEWAY unless wallet.payment_system.name == 'QIWI'

        "qiwi_#{currency}"
      end

      def currency
        @currency ||= wallet.currency.to_s.downcase
      end
    end
  end
end
