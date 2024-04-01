# frozen_string_literal: true

require_relative 'transaction'

class PaymentServices::Tronscan
  class TransactionMatcher
    def initialize(invoice:, transactions:)
      @invoice = invoice
      @transactions = transactions
      @currency = invoice.amount_currency.to_s.downcase
    end

    def perform
      send("match_#{currency}_transaction")
    end

    private

    attr_reader :invoice, :transactions, :currency

    def build_transaction(id:, created_at:, source:)
      Transaction.build_from(raw_transaction: { id: id, created_at: created_at, source: source })
    end

    def match_trx_transaction
      raw_transaction = transactions.find { |transaction| match_trx_transaction?(transaction) }
      return unless raw_transaction

      build_transaction(
        id: raw_transaction['hash'],
        created_at: timestamp_in_utc(raw_transaction['timestamp'] / 1000),
        source: raw_transaction
      )
    end

    def match_trx_transaction?(transaction)
      match_amount?(transaction['amount'], transaction['tokenInfo']['tokenDecimal']) && match_time?(transaction['timestamp'] / 1000)
    end

    def match_usdt_transaction
      raw_transaction = transactions.find { |transaction| match_usdt_transaction?(transaction) }
      return unless raw_transaction

      build_transaction(
        id: raw_transaction['transaction_id'],
        created_at: timestamp_in_utc(raw_transaction['block_ts'] / 1000),
        source: raw_transaction
      )
    end

    def match_usdt_transaction?(transaction)
      match_amount?(transaction['quant'], transaction['tokenDecimal']) && match_time?(transaction['block_ts'] / 1000)
    end

    def match_amount?(received_amount, decimals)
      amount = received_amount.to_i / 10.0 ** decimals
      amount == invoice.amount.to_f
    end

    def match_time?(timestamp)
      invoice.created_at.utc < timestamp_in_utc(timestamp)
    end

    def timestamp_in_utc(timestamp)
      Time.at(timestamp).to_datetime.utc
    end
  end
end
