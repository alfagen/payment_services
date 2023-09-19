# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PayForUH2h
  class Invoicer < ::PaymentServices::Base::Invoicer
    CURRENCY_TO_PROVIDER_BANK = {
      'UAH' => 'anyuabank',
      'RUB' => 'anyrubank'
    }
    PAYMENT_TYPE = 'card2card'
    PROVIDER_REQUISITES_FOUND_STATE = 'customer_confirm'
    PROVIDER_REQUEST_RETRIES = 5
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      deposit_id = client.create_invoice(params: invoice_params).dig('id')
      invoice.update!(deposit_id: deposit_id)
      client.update_invoice(deposit_id: deposit_id, params: invoice_h2h_params)
      client.start_payment(deposit_id: deposit_id)
      card_number, card_holder = requisites
      raise Error, 'Нет доступных реквизитов для оплаты' unless card_number.present?

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
      invoice.update_state_by_provider(transaction['status']) if valid_transaction?(transaction)
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
          bank: CURRENCY_TO_PROVIDER_BANK[currency.to_s],
          type: PAYMENT_TYPE
        }
      }
    end

    def requisites
      transaction = nil

      loop do
        attempts ||= 1
        transaction = client.transaction(deposit_id: invoice.deposit_id)

        break if transaction['status'] == PROVIDER_REQUISITES_FOUND_STATE || (attempts += 1) <= PROVIDER_REQUEST_RETRIES
        sleep 2
      end
      card_number, card_holder = transaction.dig('requisites', 'cardInfo'), transaction.dig('requisites', 'cardholder')
      client.update_invoice(deposit_id: invoice.deposit_id, params: { payment: { customerCardLastDigits: card_number.last(4) } })
      [card_number, card_holder]
    end

    def valid_transaction?(transaction)
      transaction && transaction['amount'].to_i == invoice.amount.to_i
    end

    def client
      @client ||= Client.new(api_key: api_key)
    end
  end
end
