# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Bovapay
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    PAYEER_TYPE = 'trust'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      raise Error, "Can't create invoice: #{response}" unless response['result_code'] == 'ok'

      invoice.update!(
        deposit_id: response.dig('payload', 'id'),
        pay_url: response.dig('payload', 'form_url')
      )
    end

    def pay_invoice_url
      invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction.dig('payload', 'state'))
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :card_bank, to: :bank_resolver

    def invoice_params
      {
        amount: invoice.amount.to_i,
        merchant_id: order.public_id.to_s,
        payeer_identifier: "#{Rails.env}_user_id_#{order.user_id}",
        payeer_ip: order.remote_ip,
        payeer_card_number: order.income_account,
        payeer_type: PAYEER_TYPE,
        lifetime: order.income_payment_timeout.to_i,
        redirect_url: order.success_redirect,
        payment_method: 'card',
        currency: invoice.amount_currency.to_s.downcase,
        bank_name: card_bank
      }
    end

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
