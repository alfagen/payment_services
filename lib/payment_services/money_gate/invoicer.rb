# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MoneyGate
  class Invoicer < ::PaymentServices::Base::Invoicer
    PROVIDER_SUCCESS_STATE = 0
    PAYMENT_METHOD_ID = 394
    Error = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)
      validate_response!(response)

      create_temp_kassa_wallet(address: response.dig('paymentCredentials'))
      invoice.update!(deposit_id: response.dig('id'))
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status']) if transaction
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :currency, :wallets, to: :income_payment_system

    def invoice_params
      {
        client: order.user_email,
        product: "Order #{order.public_id}",
        price: invoice.amount.to_f * 100,
        quantity: 1,
        currency: '',
        fiat_currency: 'uah',
        uuid: order.public_id.to_s,
        language: 'ru',
        message: ''
        description: "Order #{order.public_id}",
        card_number: '',
        payment_method_id: PAYMENT_METHOD_ID.to_s
      }
    end

    def create_temp_kassa_wallet(address:)
      wallet = wallets.find_or_create_by(account: address)
      order.update(income_wallet_id: wallet.id)
    end

    def validate_response!(response)
      return if response['status'] == PROVIDER_SUCCESS_STATE

      raise Error, "Can't create invoice: #{response}" 
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
