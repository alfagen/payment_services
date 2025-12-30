# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

module PaymentServices
  class PaylamaSbp
    class Invoicer < ::PaymentServices::Base::Invoicer
      def prepare_invoice_and_get_wallet!(currency:, token_network:)
        create_invoice!
        response = client.create_provider_invoice(params: invoice_fps_params)
        raise response['cause'] unless response['success']

        invoice.update!(deposit_id: response['externalID'])
        PaymentServices::Base::Wallet.new(
          address: prepare_phone_number(response['phoneNumber']),
          name: response['cardHolderName'],
          memo: response['bankName'].capitalize
        )
      end

      def create_invoice(money)
        invoice
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        transaction = client.payment_status(payment_id: invoice.deposit_id, type: 'invoice')
        invoice.update_state_by_provider(transaction['status']) if valid_transaction?(transaction)
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      delegate :income_payment_system, to: :order

      def create_invoice!
        Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      end

      def invoice_fps_params
        {
          payerID: "#{Rails.env}_user_id_#{order.user_id}",
          currencyID: currency_id,
          expireAt: order.income_payment_timeout,
          amount: invoice.amount.to_i,
          clientOrderID: order.public_id.to_s
        }
      end

      def currency_id
        PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: income_payment_system.currency).fiat_currency_id
      end

      def prepare_phone_number(provider_phone_number)
        "+#{provider_phone_number[0]} (#{provider_phone_number[1..3]}) #{provider_phone_number[4..6]}-#{provider_phone_number[7..8]}-#{provider_phone_number[9..10]}"
      end

      def valid_transaction?(transaction)
        transaction && transaction['amount'].to_i == invoice.amount.to_i
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
