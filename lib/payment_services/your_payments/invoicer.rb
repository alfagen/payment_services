# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::YourPayments
  class Invoicer < ::PaymentServices::Base::Invoicer
    PROVIDER_REQUISITES_FOUND_STATE = 'TRADER_ACCEPTED'
    PROVIDER_REQUEST_RETRIES = 3
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      card_number, card_holder, bank_name = fetch_card_details!

      PaymentServices::Base::Wallet.new(address: card_number, name: card_holder, memo: bank_name.capitalize)
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

    delegate :income_payment_system, :income_account, to: :order
    delegate :currency, to: :income_payment_system

    def invoice_params
      {
        type: 'buy',
        amount: invoice.amount_cents,
        currency: currency.to_s,
        method_type: 'card_number',
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
      status = fetch_trader
      raise Error, 'Нет доступных реквизитов для оплаты' if status.is_a? Integer

      requisites = client.requisites(invoice_id: invoice.deposit_id)
      card_number, card_holder, bank_name = transaction.dig('card'), transaction.dig('holder'), transaction.dig('bank')

      raise Error, 'Нет доступных реквизитов для оплаты' unless card_number.present?

      [card_number, card_holder, bank_name]
    end

    def fetch_trader
      PROVIDER_REQUEST_RETRIES.times do
        sleep 3

        status = client.request_requisites(params: { order_id: invoice.deposit_id, bank: provider_bank })
        break status if status == PROVIDER_REQUISITES_FOUND_STATE
      end
    end

    def provider_bank
      @provider_bank ||= PaymentServices::Base::P2pBankResolver.new(adapter: self).card_bank
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
