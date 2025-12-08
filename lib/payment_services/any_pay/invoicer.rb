# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

module PaymentServices
  class AnyPay
    class Invoicer < ::PaymentServices::Base::Invoicer
      QIWI_PAYMENT_METHOD = 'qiwi'
      CARD_PAYMENT_METHOD = 'card'

      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id)
        response = client.create_invoice(params: invoice_params)

        invoice.update!(
          deposit_id: response['transaction_id'],
          pay_url: response['payment_url']
        )
      end

      def pay_invoice_url
        invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        transaction = client.transaction(deposit_id: invoice.deposit_id)
        invoice.update_state_by_provider(transaction['status']) if transaction
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      delegate :income_payment_system, to: :order
      delegate :currency, to: :income_payment_system

      def invoice_params
        {
          pay_id: order.public_id.to_s,
          amount: invoice.amount.to_f,
          currency: currency.to_s,
          desc: order.public_id.to_s,
          method: payment_method,
          email: order.user_email,
          success_url: order.success_redirect,
          fail_url: order.failed_redirect
        }
      end

      def payway
        @payway ||= order.income_payment_system.payway.inquiry
      end

      def payment_method
        payway.qiwi? ? QIWI_PAYMENT_METHOD : CARD_PAYMENT_METHOD
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
