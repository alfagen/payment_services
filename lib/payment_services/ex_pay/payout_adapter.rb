# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'


module PaymentServices
  class ExPay
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
      PAYOUT_PROVIDER_TOKEN = 'CARDRUBP2P'

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

        transaction = client.transaction(tracker_id: payout.withdrawal_id)
        payout.update_state_by_provider(transaction['status']) if transaction
        transaction
      end

      private

      attr_reader :payout

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
        response = client.create_payout(params: payout_params)
        raise "Can't create payout: #{response['description']}" unless response['status'] == Invoice::INITIAL_PROVIDER_STATE

        payout.pay!(withdrawal_id: response['tracker_id'])
      end

      def payout_params
        order = OrderPayout.find(payout.order_payout_id).order
        {
          amount: payout.amount.to_i,
          call_back_url: order.outcome_payment_system.callback_url,
          client_transaction_id: "#{order.public_id}-#{payout.order_payout_id}",
          receiver: payout.destination_account,
          token: PAYOUT_PROVIDER_TOKEN
        }
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
