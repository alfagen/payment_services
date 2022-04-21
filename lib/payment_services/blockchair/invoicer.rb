# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'blockchain'
require_relative 'transaction_matcher'

class PaymentServices::Blockchair
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSANSACTIONS_AMOUNT_TO_CHECK = 3

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.update_invoice_details(transaction: transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def transaction_for(invoice)
      transactions = 
        if blockchain.ethereum?
          blockchair_transactions(invoice: invoice)['calls']
        elsif blockchain.cardano?
          blockchair_transactions(invoice: invoice)['address']['caTxList']
        elsif blockchain.stellar?
          blockchair_transactions(invoice: invoice)['payments']
        else
          transactions_outputs(transactions_data_for(invoice))
        end

      TransactionMatcher.new(invoice: invoice, transactions: transactions).matched_transaction
    end

    def blockchair_transactions(invoice:)
      client.transactions(address: invoice.address)['data'][invoice.address]
    end

    def transactions_data_for(invoice)
      transaction_ids_on_wallet = blockchair_transactions(invoice: invoice)['transactions']
      client.transactions_data(tx_ids: transaction_ids_on_wallet.first(TRANSANSACTIONS_AMOUNT_TO_CHECK))['data']
    end

    def transactions_outputs(transactions_data)
      outputs = []

      transactions_data.each do |_transaction_id, transaction|
        outputs << transaction['outputs']
      end

      outputs.flatten
    end

    def blockchain
      @blockchain ||= Blockchain.new(currency: order.income_wallet.currency.to_s.downcase)
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        currency = wallet.currency.to_s.downcase

        Client.new(api_key: api_key, currency: currency)
      end
    end
  end
end
