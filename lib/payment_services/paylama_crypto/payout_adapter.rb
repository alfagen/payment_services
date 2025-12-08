# frozen_string_literal: true

require_relative 'payout'
require_relative 'transaction'


module PaymentServices
  class PaylamaCrypto
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

        raw_transaction = client.payment_status(payment_id: payout.withdrawal_id, type: 'withdraw')
        raise "Can't get payment information: #{raw_transaction}" unless raw_transaction['ID']

        transaction = Transaction.build_from(raw_transaction)
        payout.update_state_by_transaction(transaction)
        raw_transaction
      end

      private

      attr_reader :payout

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
        response = client.process_crypto_payout(params: payout_params)
        raise "Can't create payout: #{response}" unless response['ID']

        payout.pay!(withdrawal_id: response['ID'])
      end

      def payout_params
        {
          amount: payout.amount.to_f,
          currency: currency,
          address: payout.destination_account
        }
      end

      def currency
        @currency ||= PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: wallet.currency, token_network: wallet.payment_system.token_network).provider_crypto_currency
      end

      def client
        @client ||= PaymentServices::Paylama::Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
