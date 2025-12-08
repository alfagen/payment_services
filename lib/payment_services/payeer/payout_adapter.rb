# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'


module PaymentServices
  class Payeer
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter

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

        response = client.payments(params: { account: wallet.num_ps })

        raise "Can't get withdrawal details: #{response['errors']}" if response['errors'].any?

        payment = response['history'].values.find do |payment|
          payment['referenceId'] == payout.reference_id
        end

        payout.update_provider_state(payment['status']) if payment

        payment
      end

      private

      def make_payout(amount:, destination_account:, order_payout_id:)
        payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)

        params = {
          account: wallet.num_ps,
          sumOut: amount.to_d,
          to: destination_account,
          comment: "Перевод по заявке №#{payout.order_payout.order.public_id} на сайте Kassa.cc",
          referenceId: payout.build_reference_id
        }
        response = client.create_payout(params: params)

        raise "Can't process payout: #{response['errors']}" if response['errors'].is_a? Array

        payout.pay!
      end

      def client
        @client ||= Client.new(api_id: wallet.merchant_id, api_key: api_key, currency: wallet.currency.to_s, account: wallet.num_ps, secret_key: api_secret)
      end
    end
  end
end
