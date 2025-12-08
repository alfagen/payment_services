# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'


module PaymentServices
  class XPayProVirtual
    class Invoicer < ::PaymentServices::Base::Invoicer
      def prepare_invoice_and_get_wallet!(currency:, token_network:)
        create_invoice!
        response = client.create_invoice(params: invoice_p2p_params)
        raise response['message'] if response['code']

        invoice.update!(
          deposit_id: response.dig('tx', 'tx_id'),
          rate: response.dig('tx', 'rate').to_f
        )
        PaymentServices::Base::Wallet.new(
          address: response.dig('tx', 'payment_requisite'),
          name: nil,
          memo: response.dig('tx', 'payment_system').downcase.capitalize
        )
      end

      def create_invoice(money)
        invoice
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        transaction = client.transaction(deposit_id: invoice.deposit_id)
        invoice.update_state_by_provider(transaction.dig('tx', 'tx_status')) if transaction_valid?(transaction)
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      def create_invoice!
        Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      end

      def invoice_p2p_params
        {
          fiat_currency: 'RUB',
          fiat_amount: invoice.amount.to_f.to_s,
          crypto_currency: 'USDT',
          payment_method: 'BANK_ACCOUNT',
          bank_name: provider_bank,
          merchant_tx_id: order.public_id.to_s,
          merchant_client_id: "#{Rails.env}_user_id_#{order.user_id}"
        }
      end

      def transaction_valid?(transaction)
        amount_confirmed = transaction.dig('tx', 'in_amount_confirmed')
        amount_confirmed.to_f == invoice.amount.to_f || amount_confirmed == '0'
      end

      def provider_bank
        @provider_bank ||= PaymentServices::Base::P2pBankResolver.new(adapter: self).card_bank
      end

      def client
        @client ||= Client.new(api_key: api_key)
      end
    end
  end
end
