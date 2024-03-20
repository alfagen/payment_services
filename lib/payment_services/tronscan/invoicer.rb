# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'transaction_matcher'

class PaymentServices::Tronscan
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.update_invoice_details(transaction: transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :currency, to: :income_payment_system

    def transaction_for(invoice)
      TransactionMatcher.new(invoice: invoice, transactions: collect_transactions, currency: currency).perform
    end

    def collect_transactions
      client.transactions(address: invoice.address)
    end

    def client
      @client ||= Client.new(api_key: api_key, currency: currency.to_s.downcase)
    end
  end
end
