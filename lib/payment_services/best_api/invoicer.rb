# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::BestApi
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(amount: money.to_i, currency: money.currency.to_s)
 
      create_temp_kassa_wallet(address: response['card_number'])
      invoice.update!(deposit_id: response['trade'])
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

    def create_temp_kassa_wallet(address:)
      wallet = wallets.find_or_create_by(account: address)
      order.update(income_wallet_id: wallet.id)
    end

    def client
      @client ||= Client.new(api_key: api_key)
    end
  end
end
