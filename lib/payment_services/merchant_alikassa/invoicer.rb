# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MerchantAlikassa
  class Invoicer < ::PaymentServices::Base::Invoicer
    DEFAULT_USER_AGENT = 'Chrome/47.0.2526.111'
    SBP_SERVICE = 'payment_card_sbp_rub'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise response['message'] if response['errors']

      invoice.update!(deposit_id: response['id'])
      PaymentServices::Base::Wallet.new(
        address: response['cardNumber'],
        name: response['cardHolderName']
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice_transaction(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['payment_status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :currency, to: :income_payment_system
    delegate :card_bank, :sbp_bank, :sbp?, to: :bank_resolver

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      {
        amount: invoice.amount.to_f.round(1),
        order_id: order.public_id.to_s,
        service: sbp? ? SBP_SERVICE : "payment_card_number_#{currency.to_s.downcase}_card",
        customer_code: sbp? ? sbp_bank : card_bank,
        customer_user_id: "#{Rails.env}_user_id_#{order.user_id}",
        customer_ip: order.remote_ip,
        customer_browser_user_agent: DEFAULT_USER_AGENT,
        success_redirect_url: order.success_redirect,
        fail_redirect_url: order.failed_redirect
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
