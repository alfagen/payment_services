# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

module PaymentServices
  class Paycraft
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
      Error = Class.new StandardError
      SBP_PAYWAY = 'СБП'
      CARD_PAYWAY = 'Межбанк'

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

        transaction = client.payout(params: { clientUniqueId: payout.withdrawal_id })
        payout.update_state_by_provider(transaction['status'])
        transaction
      end

      private

      delegate :sbp?, :sbp_bank, to: :bank_resolver

      attr_reader :payout

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
        response = client.create_payout(params: payout_params)
        raise Error, "Can't create payout: #{response['reason']}" if response['reason'].present?

        payout.pay!(withdrawal_id: unique_id)
      end

      def unique_id
        @unique_id ||= "#{OrderPayout.find(payout.order_payout_id).order.public_id}-#{payout.order_payout_id}"
      end

      def payout_params
        {
          clientUniqueId: unique_id,
          destination: payout.destination_account,
          amount: payout.amount.to_i,
          walletId: sbp? ? SBP_PAYWAY : CARD_PAYWAY,
          expiredTime: 30,
          expiredOfferTime: 600,
          sbp_bank: sbp? ? sbp_bank : ''
        }
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
