# frozen_string_literal: true

require_relative 'client'
require_relative 'payout'
require_relative 'invoice'
require_relative 'transaction'

module PaymentServices
  class Ff
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
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

        raw_transaction = client.transaction(params: { id: payout.withdrawal_id, token: payout.access_token })
        transaction = Transaction.build_from(raw_transaction['data'], direction: :to)
        payout.update_state_by_provider!(transaction)

        transaction
      end

      def payout
        @payout ||= Payout.find_by(id: payout_id)
      end

      private

      attr_accessor :payout_id

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout_id = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id).id

        invoice = Invoice.find_by!(order_public_id: OrderPayout.find(payout.order_payout_id).order.public_id)

        payout.pay!(withdrawal_id: invoice.deposit_id)
        payout.update!(access_token: invoice.access_token)
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
