# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Bridgex
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    PAYMENT_TIMEOUT_IN_SECONDS = 1800
    UNUSED_BANK_PARAM = 'unused_param'

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

    delegate :card_bank, :sbp_bank, :sbp?, to: :resolver
    delegate :require_income_card_verification, to: :income_payment_system
    delegate :income_unk, :income_payment_system, to: :order

    def invoice_params
      params = {
        amount: invoice.amount.to_i,
        order: order.public_id.to_s,
        customer_ip: order.remote_ip,
        customer_ident: '1',
        card: card_payment?,
        sbp: sbp_payment?,
        qr: 'no',
        ttl: PAYMENT_TIMEOUT_IN_SECONDS
      }
      params[:category] = 17 if !require_income_card_verification
      params[:bank] = card_bank if !sbp? && card_bank != UNUSED_BANK_PARAM
      params[:bank] = sbp_bank if sbp? && sbp_bank.present?
      params
    end

    def resolver
      @resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def sbp_payment?
      sbp? ? 'yes' : 'no'
    end

    def card_payment?
      sbp? ? 'no' : 'yes'
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
