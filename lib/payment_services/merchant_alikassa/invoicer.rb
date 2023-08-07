# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MerchantAlikassa
  class Invoicer < ::PaymentServices::Base::Invoicer
    DEFAULT_USER_AGENT = 'Chrome/47.0.2526.111'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      invoice.update!(
        deposit_id: response['id'],
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
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['payment_status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :currency, to: :income_payment_system

    def invoice_params
      {
        amount: invoice.amount.to_f,
        order_id: order.public_id.to_s,
        service: "payment_card_#{currency.to_s.downcase}_hpp",
        customer_ip: order.remote_ip,
        customer_browser_user_agent: DEFAULT_USER_AGENT,
        success_redirect_url: order.success_redirect,
        fail_redirect_url: order.failed_redirect
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
