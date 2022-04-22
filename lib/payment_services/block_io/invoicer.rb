# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'transaction'

class PaymentServices::BlockIo
  class Invoicer < ::PaymentServices::Base::Invoicer
    TransactionsHistoryRequestFailed = Class.new StandardError
    RESPONSE_SUCCESS_STATUS = 'success'

    delegate :income_wallet, to: :order

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = transactions_for(invoice)
      return if transaction.nil?

      invoice.update_invoice_details(transaction: transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def transaction_for(invoice)
      transactions = collect_transactions_on(address: invoice.address)
      raw_transaction = transactions.find { |transaction| match_transaction?(transaction) }
      Transaction.build_from(raw_transaction: raw_transaction) if raw_transaction
    end

    def collect_transactions_on(address:)
      response = client.income_transactions(address)
      response_status = response['status']
      raise TransactionsHistoryRequestFailed, response.to_s unless response_status == RESPONSE_SUCCESS_STATUS

      response['data']['txs']
    end

    def match_transaction?(transaction)
      transaction_created_at = Time.at(raw_transaction['time']).to_datetime.utc
      invoice_created_at = invoice.created_at.utc
      amount = parse_amount(transaction)

      match_timing?(invoice_created_at, transaction_created_at) && match_amount?(amount)
    end

    def match_timing?(invoice_created_at, transaction_created_at)
      invoice_created_at < transaction_created_at
    end

    def match_amount?(amount)
      amount.to_d == invoice.amount.to_d
    end

    def parse_amount(transaction)
      received = transaction['amounts_received'].find { |received| received['recipient'] == invoice.address }
      received ? received['amount'] : 0
    end

    def client
      @client ||= begin
        api_key = income_wallet.api_key.presence || income_wallet.parent&.api_key

        Client.new(api_key: api_key, pin: '')
      end
    end
  end
end
