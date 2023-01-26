# frozen_string_literal: true

require_relative 'transaction'

class PaymentServices::PaylamaCrypto
  class TransactionRepository
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    BASIC_TIME_COUNTDOWN = 1.minute

    def initialize(transactions)
      @transactions = transactions
    end

    def find_for(invoice)
      @invoice = invoice
      send("find_#{currency}_transaction")
    end

    private

    attr_reader :transactions, :invoice

    def currency
      @currency ||= invoice.amount_currency.downcase
    end

    def method_missing(method_name)
      super unless method_name.start_with?('find_') && method_name.end_with?('_transaction')

      raw_transaction = transactions.find { |transaction| find_generic_transaction?(transaction) }
      return unless raw_transaction

      Transaction.build_from(
        currency: currency,
        status: raw_transaction['status'],
        created_at: timestamp_in_utc(raw_transaction['createdAt']),
        fee: raw_transaction['fee'],
        source: raw_transaction
      )
    end

    def find_generic_transaction?(transaction)
      amount = Money.from_amount(transaction['amount'].to_d, transaction['currency'])
      transaction_created_at = timestamp_in_utc(transaction['createdAt'])
      invoice_created_at = invoice.created_at.utc

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      invoice_created_at < transaction_created_at && match_by_amount_and_time?(amount, time_diff)
    end

    def match_by_amount_and_time?(amount, time_diff)
      match_amount?(amount) && match_transaction_time_threshold?(time_diff)
    end

    def match_amount?(received_amount)
      received_amount == invoice.amount
    end

    def match_transaction_time_threshold?(time_diff)
      time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
    end

    def timestamp_in_utc(timestamp)
      DateTime.strptime(timestamp.to_s,'%s').utc
    end
  end
end
