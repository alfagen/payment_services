# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'transaction_repository'

module PaymentServices
  class CryptoApisV2
    class Invoicer < ::PaymentServices::Base::Invoicer
      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
      end

      def update_invoice_state!
        transaction = transaction_for(invoice)
        return if transaction.nil?

        invoice.update_invoice_details!(transaction: transaction)
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      def async_invoice_state_updater?
        true
      end

      private

      def transaction_for(invoice)
        TransactionRepository.new(collect_transactions).find_for(invoice)
      end

      def collect_transactions
        response = client.address_transactions(invoice)
        raise response['error']['message'] if response['error']

        response['data']['items']
      end

      def wallet
        @wallet ||= order.income_wallet
      end

      def client
        @client ||= Client.new(api_key: api_key, api_secret: api_secret, currency: wallet.currency.to_s.downcase, token_network: wallet.payment_system.token_network)
      end
    end
  end
end
