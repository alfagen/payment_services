# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'transaction'


module PaymentServices
  class OneCrypto
    class Invoicer < ::PaymentServices::Base::Invoicer
      def prepare_invoice_and_get_wallet!(currency:, token_network:)
        invoice_params = {
          token: PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: currency, token_network: token_network).provider_crypto_currency,
          client_transaction_id: order.id_in_unixtime.to_s,
          call_back_url: order.income_payment_system.callback_url
        }

        response = client.create_invoice(params: invoice_params)
        raise "Can't create invoice: #{response['description']}" unless response['status'] == Invoice::INITIAL_PROVIDER_STATE

        PaymentServices::Base::Wallet.new(address: response['refer'], name: response['tracker_id'])
      end

      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id)
        invoice.update!(deposit_id: order.income_wallet.name)
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        raw_transaction = client.transaction(tracker_id: invoice.deposit_id)
        transaction = Transaction.build_from(raw_transaction)
        invoice.update_state_by_transaction!(transaction)
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
