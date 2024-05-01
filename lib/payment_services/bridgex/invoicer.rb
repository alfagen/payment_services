# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Bridgex
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    PAYMENT_TIMEOUT_IN_SECONDS = 900

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      raise Error, "Can't create invoice: #{response}" if response['message']

      invoice.update!(
        deposit_id: order.public_id.to_s,
        pay_url: response.dig('result', 'url')
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
      invoice.update_state_by_provider(transaction.dig('result', 'payment_status'))
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_unk, to: :order

    def invoice_params
      {
        amount: invoice.amount.to_i,
        order: order.public_id.to_s,
        customer_ident: '0',
        card: card?,
        sbp: sbp?,
        qr: 'no',
        ttl: PAYMENT_TIMEOUT_IN_SECONDS,
        bank: provider_bank
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
