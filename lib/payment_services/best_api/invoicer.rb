# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::BestApi
  class Invoicer < ::PaymentServices::Base::Invoicer
    def income_wallet(currency:, token_network:)
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      response = client.income_wallet(amount: order.calculated_income_money.to_i, currency: currency.to_s)

      invoice.update!(deposit_id: response['trade'])
      PaymentServices::Base::Wallet.new(address: response['card_number'].split('|').first, name: nil)
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['message']) if transaction
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def client
      @client ||= Client.new(api_key: api_key)
    end
  end
end
