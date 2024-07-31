# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Erapay
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      raise Error, "Can't create invoice: #{response['data']['message']}" if response['data']['message'].present?

      invoice.update!(
        deposit_id: response.dig('data', 'info', 'order_id'),
        pay_url: response['data']['link']
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

    delegate :sbp?, to: :bank_resolver

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def invoice_params
      {
        unique_id: order.public_id.to_s,
        amount: invoice.amount.to_i,
        description: "Order ##{order.public_id.to_s}",
        user_ip: order.remote_ip,
        system_name: sbp? ? 'sbp' : 'card'
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
