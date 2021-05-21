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

      update_invoice_details(transaction: transaction)
      invoice.pay!(payload: transaction) if invoice.complete_payment?
    end

    def async_invoice_state_updater?
      true
    end

    private

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def update_invoice_details(transaction:)
      invoice.transaction_created_at ||= DateTime.strptime(transaction['created_at'].to_s, '%s').utc
      invoice.transaction_id ||= transaction['transaction_hash']
      invoice.provider_state = transaction['state']

      invoice.save!
    end

    def transaction_for(invoice)
      response = client.address_transactions
      raise response['message'] if response['message']
      return unless response['models']

      response['models'].find do |transaction|
        received_amount = transaction['gross_amount']
        received_amount.to_d == invoice.amount.to_d && DateTime.strptime(transaction['created_at'].to_s, '%s').utc > invoice.created_at.utc
      end
    end

    def client
      @client ||= begin
        Client.new(currency: order.income_wallet.currency.to_s)
      end
    end
  end
end
