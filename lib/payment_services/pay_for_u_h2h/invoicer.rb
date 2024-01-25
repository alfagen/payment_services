# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PayForUH2h
  class Invoicer < ::PaymentServices::Base::Invoicer
    PAYMENT_TYPE = 'card2card'
    PROVIDER_REQUISITES_FOUND_STATE = 'customer_confirm'
    PROVIDER_REQUEST_RETRIES = 5
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      update_provider_invoice_and_start_payment
      card_number, card_holder = fetch_card_details!

      PaymentServices::Base::Wallet.new(address: card_number, name: card_holder)
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      if valid_transaction?(transaction)
        invoice.update(last_4_digits: transaction.dig('payment', 'customerCardLastDigits'))
        invoice.update_state_by_provider(transaction['status'])
      end
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def confirm_payment
      client.confirm_payment(deposit_id: invoice.deposit_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :currency, to: :income_payment_system

    def invoice_params
      {
        amount: invoice.amount.to_i,
        currency: currency.to_s,
        customer: {
          id: order.user_id.to_s,
          email: order.user_email
        },
        integration: {
          externalOrderId: order.public_id.to_s,
          returnUrl: order.success_redirect
        }
      }
    end

    def invoice_h2h_params
      {
        payment: {
          bank: provider_bank,
          type: PAYMENT_TYPE
        }
      }
    end

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      deposit_id = client.create_invoice(params: invoice_params).dig('id')
      invoice.update!(deposit_id: deposit_id)
    end

    def update_provider_invoice_and_start_payment
      update_provider_invoice(params: invoice_h2h_params)
      client.start_payment(deposit_id: invoice.deposit_id)
    end

    def update_provider_invoice(params:)
      client.update_invoice(deposit_id: invoice.deposit_id, params: params)
    end

    def fetch_card_details!
      transaction = fetch_transaction
      raise Error, 'Нет доступных реквизитов для оплаты' if transaction.is_a? Integer

      card_number, card_holder = transaction.dig('requisites', 'cardInfo'), transaction.dig('requisites', 'cardholder')
      update_provider_invoice(params: { payment: { customerCardLastDigits: card_number.last(4) } })
      [card_number, card_holder]
    end

    def fetch_transaction
      PROVIDER_REQUEST_RETRIES.times do
        sleep 3

        transaction = client.transaction(deposit_id: invoice.deposit_id)
        break transaction if transaction['status'] == PROVIDER_REQUISITES_FOUND_STATE
      end
    end

    def valid_transaction?(transaction)
      transaction && transaction['amount'].to_i == invoice.amount.to_i
    end

    def provider_bank
      @provider_bank ||= PaymentServices::Base::P2pBankResolver.new(adapter: self, direction: :income).provider_bank
    end

    def client
      @client ||= Client.new(api_key: api_key)
    end
  end
end
