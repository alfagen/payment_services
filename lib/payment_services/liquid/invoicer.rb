# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Liquid
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def wallet_address(currency:)
      wallet = Client.new(currency: currency).wallet

      wallet['address']
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.pay!(payload: transaction)
    end

    def invoice
      {}
    end

    def async_invoice_state_updater?
      true
    end

    private

    def transaction_for(invoice)
      response = client.address_transactions
      raise response[:message] if response.dig(:message)

      response[:models].find do |transaction|
        received_amount = transaction[:gross_amount]
        received_amount.to_d == invoice.amount.to_d && DateTime.strptime(transaction[:created_at].to_s, '%s') > invoice.created_at
      end if response[:models]
    end

    def client
      @client ||= begin
        Client.new(currency: 'TRX')
      end
    end
  end
end
