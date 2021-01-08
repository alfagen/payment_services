# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'client'

class PaymentServices::CryptoApis
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.update!(
        transaction_id: invoice.transaction_id || transaction[:txid],
        confirmations: transaction[:confirmations]
      )
      invoice.pay!(payload: transaction) if invoice.complete_payment?
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def transaction_for(invoice)
      if invoice.transaction_id
        client.transaction_details(invoice.transaction_id)[:payload]
      else
        currency = invoice.amount_currency.to_s
        response = client.address_transactions(invoice.address)
        response[:payload].find do |transaction|
          received_amount = transaction[:received][invoice.address]
          received_amount&.to_d == invoice.amount.to_d && Time.parse(transaction[:datetime]) > invoice.created_at
        end
      end
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        Client.new(api_key: api_key, currency: order.currency)
      end
    end
  end
end
