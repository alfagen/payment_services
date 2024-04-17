# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::YourPayments
  class Invoicer < ::PaymentServices::Base::Invoicer
    PROVIDER_REQUISITES_FOUND_STATE = 'TRADER_ACCEPTED'
    PROVIDER_REQUEST_RETRIES = 3
    CARD_METHOD_TYPE = 'card_number'
    SBP_METHOD_TYPE  = 'phone_number'

    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      card_number, card_holder, bank_name = fetch_card_details!

      PaymentServices::Base::Wallet.new(address: card_number, name: card_holder, memo: bank_name)
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def confirm_payment
      client.confirm_payment(deposit_id: invoice.deposit_id)
    end

    private

    delegate :income_payment_system, :income_unk, to: :order
    delegate :currency, to: :income_payment_system

    def invoice_params
      {
        type: 'buy',
        amount: invoice.amount_cents,
        currency: currency.to_s,
        method_type: method_type,
        customer_id: order.user_id.to_s,
        invoice_id: order.public_id.to_s
      }
    end

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      deposit_id = client.create_invoice(params: invoice_params).dig('order_id')
      invoice.update!(deposit_id: deposit_id)
    end

    def update_provider_invoice(params:)
      client.update_invoice(deposit_id: invoice.deposit_id, params: params)
    end

    def fetch_card_details!
      status = request_trader
      raise Error, 'Нет доступных реквизитов для оплаты' unless status == PROVIDER_REQUISITES_FOUND_STATE

      payment_details = client.payment_details(invoice_id: invoice.deposit_id)
      number = payment_details['card']
      number = prepare_phone_number(number) if sbp_payment?

      [number, payment_details['holder'], payment_details['bank']]
    end

    def request_trader
      PROVIDER_REQUEST_RETRIES.times do
        sleep 2

        status = client.request_payment_details(params: { order_id: invoice.deposit_id, bank: provider_bank })
        break status if status == PROVIDER_REQUISITES_FOUND_STATE
      end
    end

    def provider_bank
      resolver = PaymentServices::Base::P2pBankResolver.new(adapter: self)
      sbp_payment? ? resolver.sbp_bank : resolver.card_bank
    end

    def method_type
      sbp_payment? ? SBP_METHOD_TYPE : CARD_METHOD_TYPE
    end

    def sbp_payment?
      @sbp_payment ||= income_unk.present?
    end

    def prepare_phone_number(provider_phone_number)
      "#{provider_phone_number[0..1]} (#{provider_phone_number[2..4]}) #{provider_phone_number[5..7]}-#{provider_phone_number[8..9]}-#{provider_phone_number[10..11]}"
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
