# frozen_string_literal: true

require_relative 'transaction'

class PaymentServices::Tronscan
  class TransactionMatcher
    def initialize(invoice:, transactions:)
      @invoice = invoice
      @transactions = transactions
    end

    def perform
      match_transaction
    end

    private

    attr_reader :invoice, :transactions

    def build_transaction(id:, created_at:, source:)
      Transaction.build_from(raw_transaction: { id: id, created_at: created_at, source: source })
    end

    def match_transaction
      raw_transaction = transactions.find { |transaction| match_transaction?(transaction) }
      return unless raw_transaction

      build_transaction(
        id: raw_transaction['hash'],
        created_at: timestamp_in_utc(raw_transaction['block_timestamp'] / 1000),
        source: raw_transaction
      )
    end

    def match_transaction?(transaction)
      match_amount?(transaction['amount'], transaction['decimals']) && match_time?(transaction['block_timestamp'] / 1000)
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
