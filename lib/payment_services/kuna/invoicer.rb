# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

module PaymentServices
  class Kuna
    class Invoicer < ::PaymentServices::Base::Invoicer
      PAY_URL = 'https://paygate.kuna.io/hpp'

      def create_invoice(money)
        invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

        params = {
          amount: invoice.amount.to_f,
          currency: currency,
          payment_service: payment_service,
          return_url: order.success_redirect,
          callback_url: order.income_payment_system.callback_url
        }

        params[:fields] = { required_field_name => order.income_account } unless payment_card_uah?

        response = client.create_deposit(params: params)

        raise "Can't create invoice: #{response['messages']}" if response['messages']

        invoice.update!(
          deposit_id: response['deposit_id'],
          payment_invoice_id: response['payment_invoice_id']
        )
      end

      def pay_invoice_url
        uri = URI.parse(PAY_URL)
        uri.query = { cpi: invoice.reload.payment_invoice_id }.to_query

        uri
      end

      private

      def payment_card_uah?
        payway == 'visamc' && currency == 'uah'
      end

      def currency
        @currency ||= invoice.amount.currency.to_s.downcase
      end

      def invoice
        @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
      end

      def payway
        @payway ||= order.income_wallet.payment_system.payway
      end

      def payment_service
        available_options = {
          'visamc' => "payment_card_#{currency}_hpp",
          'qiwi'   => "qiwi_#{currency}_hpp"
        }
        available_options[payway]
      end

      def required_field_name
        required_field_for = {
          'visamc' => 'card_number',
          'qiwi'   => 'phone'
        }
        required_field_for[payway]
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
