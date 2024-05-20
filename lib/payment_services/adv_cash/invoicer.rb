# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'client'

class PaymentServices::AdvCash
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      invoice.update!(
        deposit_id: response['id'],
        pay_url: response['paymentUrl']
      )
    end

    def pay_invoice_url
      invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.find_invoice(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def invoice_params
      {
        amount: invoice.formatted_amount,
        currency: invoice.amount_currency.to_s,
        receiver: wallet.adv_cash_merchant_email,
        orderId: order.public_id.to_s,
        redirectUrl: order.success_redirect
      }
    end

    def client
      @client ||= Client.new(api_name: wallet.merchant_id, authentication_token: api_key, account_email: wallet.adv_cash_merchant_email)
    end
  end
end
