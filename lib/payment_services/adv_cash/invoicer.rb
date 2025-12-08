# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'client'


module PaymentServices
  class AdvCash
    class Invoicer < ::PaymentServices::Base::Invoicer
      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id)
        response = client.create_invoice(params: invoice_params).dig(:create_p2p_order_response, :return)

        invoice.update!(
          deposit_id: response[:order_id],
          pay_url: response[:payment_url]
        )
      end

      def pay_invoice_url
        invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        transaction = client.find_invoice(deposit_id: invoice.deposit_id).dig(:find_p2p_order_by_order_id_response, :return)
        invoice.update_state_by_provider(transaction[:status])
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      def invoice_params
        currency = invoice.amount_currency.to_s
        currency = 'RUR' if currency == 'RUB'
        {
          amount: invoice.formatted_amount,
          currency: currency,
          receiver: order.income_wallet.adv_cash_merchant_email,
          orderId: order.public_id.to_s,
          redirectUrl: order.success_redirect
        }
      end

      def client
        @client ||= Client.new(api_name: order.income_wallet.merchant_id, authentication_token: api_key, account_email: order.income_wallet.adv_cash_merchant_email)
      end
    end
  end
end
