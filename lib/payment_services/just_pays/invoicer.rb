# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::JustPays
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      raise Error, "Can't create invoice: #{response['error']}" if response['error']

      invoice.update!(
        deposit_id: response['internal_id'],
        pay_url: response['payment_url']
      )
    end

    def pay_invoice_url
      invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
    end

    def async_invoice_state_updater?
      false
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def invoice_params
      {
        external_id: order.public_id.to_s,
        external_meta: {
          uid: order.user_id.to_s,
          ip: order.remote_ip,
          email: order.user_email
        },
        currency_symbol: invoice.amount_currency.to_s,
        region_code: invoice.amount_currency.to_s.first(2),
        gross_amount: format('%.2f', invoice.amount.to_f),
        success_url: order.success_redirect,
        failed_url: order.failed_redirect,
        callback_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/just_pays/receive_payment"
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
