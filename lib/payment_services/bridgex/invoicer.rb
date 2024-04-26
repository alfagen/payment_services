# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Bridgex
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      raise Error, "Can't create invoice: #{response}" if response['message']

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
      transaction = client.transaction(deposit_id: invoice.deposit_id)

      invoice.update_state_by_provider(transaction['payment_status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_unk, to: :order

    def invoice_params
      {
        order: order.public_id.to_s,
        customer_ip: order.remote_ip,
        customer_ident: '1',
        card: card?,
        sbp: sbp?,
        qr: 'no',
        ttl: order.income_payment_timeout.to_i,
        url_redirect: order.success_redirect,
        bank: provider_bank,
        test_mode: 'no'
      }
    end

    def provider_bank
      resolver = PaymentServices::Base::P2pBankResolver.new(adapter: self)
      sbp_payment? ? resolver.sbp_bank : resolver.card_bank
    end

    def sbp?
      sbp_payment? ? 'yes' : 'no'
    end

    def card?
      sbp_payment? ? 'no' : 'yes'
    end

    def sbp_payment?
      @sbp_payment ||= income_unk.present?
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
