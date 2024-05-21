# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Payeer
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      invoice.update!(
        deposit_id: order.public_id.to_s,
        pay_url: response['url']
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
      invoice.update_state_by_provider(transaction['items'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def client
      @client ||= Client.new(api_id: order.income_wallet.merchant_id, api_key: api_key, currency: order.income_wallet.currency.to_s, account: order.income_wallet.num_ps, secret_key: api_secret)
    end

    def invoice_params
      {
        m_shop: order.income_wallet.merchant_id,
        m_orderid: order.public_id.to_s,
        m_amount: invoice.amount.to_d,
        m_curr: invoice.amount_currency.to_s,
        m_desc: "##{order.public_id}"
      }
    end
  end
end
