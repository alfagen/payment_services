# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'blockchain'
require_relative 'transaction_matcher'

class PaymentServices::Blockchair
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSANSACTIONS_AMOUNT_TO_CHECK = 3
    TransactionsHistoryRequestFailed = Class.new StandardError

    delegate :income_wallet, to: :order
    delegate :currency, to: :income_wallet

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
      TransactionMatcher.new(invoice: invoice, transactions: collect_transactions).perform
    end

    def collect_transactions
      if blockchain.ethereum?
        blockchair_transactions_by_address(invoice.address)['calls']
      elsif blockchain.cardano?
        blockchair_transactions_by_address(invoice.address)['address']['caTxList']
      elsif blockchain.stellar?
        blockchair_transactions_by_address(invoice.address)['payments']
      elsif blockchain.ripple?
        blockchair_transactions_by_address(invoice.address)['transactions']['transactions']
      elsif blockchain.eos?
        blockchair_transactions_by_address(invoice.address)['actions']
      elsif blockchain.erc_20?
        blockchair_transactions_by_address(invoice.address.downcase)['transactions']
      else
        transactions_outputs(transactions_data_for_address(invoice.address))
      end
    end

    def blockchair_transactions_by_address(address)
      transactions = client.transactions(address: address)['data']
      raise TransactionsHistoryRequestFailed, 'Check the payment address' unless transactions
 
      transactions[address]
    end

    def transactions_data_for_address(address)
      transaction_ids_on_wallet = blockchair_transactions_by_address(address)['transactions']
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
      @blockchain ||= Blockchain.new(currency: currency.to_s.downcase)
    end

    def client
      @client ||= begin
        api_key = income_wallet.api_key.presence || income_wallet.parent&.api_key

        Client.new(api_key: api_key, currency: currency.to_s.downcase)
      end
    end
  end
end
