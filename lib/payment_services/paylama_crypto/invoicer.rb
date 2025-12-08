# frozen_string_literal: true

require_relative 'invoice'
require_relative 'transaction'


module PaymentServices
  class PaylamaCrypto
    class Invoicer < ::PaymentServices::Base::Invoicer
      def create_invoice(money)
        Invoice.create(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
      end

      def prepare_invoice_and_get_wallet!(currency:, token_network:)
        provider_crypto_currency = PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: currency, token_network: token_network).provider_crypto_currency
        response = client.create_crypto_address(currency: provider_crypto_currency)
        raise "Can't create crypto address: #{response['cause']}" unless response['id']

        PaymentServices::Base::Wallet.new(address: response['address'], name: response['id'])
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        raw_transaction = client.payment_status(payment_id: order.income_wallet.name, type: 'invoice')
        raise "Can't get payment information: #{raw_transaction['cause']}" unless raw_transaction['ID']

        transaction = Transaction.build_from(raw_transaction)
        invoice.update_state_by_transaction(transaction)
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      def client
        @client ||= PaymentServices::Paylama::Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
