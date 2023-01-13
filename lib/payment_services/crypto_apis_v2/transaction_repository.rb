# frozen_string_literal: true

require_relative 'transaction'
require_relative 'blockchain'

class PaymentServices::CryptoApisV2
  class TransactionRepository
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    BASIC_TIME_COUNTDOWN = 1.minute

    def initialize(transactions)
      @transactions = transactions
    end

    def find_for(invoice)
      @invoice = invoice
      send("find_#{invoice.amount_currency}_transaction")
    end

    private

    attr_reader :invoice, :transactions

    def currency
      @currency ||= wallet.currency.to_s.downcase
    end

    def wallet
      @wallet ||= invoice.order.income_wallet
    end

    def build_transaction(id:, created_at:, currency:, source:)
      Transaction.build_from(transaction_hash: id, created_at: created_at, currency: currency, source: source)
    end

    def method_missing(method_name)
      super unless method_name.start_with?('find_') && method_name.end_with?('_transaction')

      raw_transaction = transactions.find { |transaction| find_generic_transaction?(transaction) }
      return unless raw_transaction

      build_transaction(
        id: raw_transaction['transactionHash'],
        created_at: timestamp_in_utc(raw_transaction['timestamp']),
        currency: currency,
        source: raw_transaction
      )
    end

    def find_generic_transaction?(transaction)
      amount = parse_received_amount(transaction)
      transaction_created_at = timestamp_in_utc(transaction['timestamp'])
      invoice_created_at = invoice.created_at.utc

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      invoice_created_at < transaction_created_at && match_by_amount_and_time?(amount, time_diff)
    end

    def find_usdt_transaction
      raw_transaction = transactions.find { |transaction| find_token?(transaction) }
      return unless raw_transaction

      build_transaction(
        id: raw_transaction['transactionId'],
        created_at: timestamp_in_utc(transaction['timestamp']),
        currency: currency,
        source: raw_transaction
      )
    end

    def find_bnb_transaction
      raw_transaction = transactions.find { |transaction| find_token?(transaction) }
      return unless raw_transaction

      build_transaction(
        id: raw_transaction['transactionId'],
        created_at: timestamp_in_utc(transaction['timestamp']),
        currency: currency,
        source: raw_transaction
      )
    end

    def match_by_amount_and_time?(amount, time_diff)
      match_amount?(amount) && match_transaction_time_threshold?(time_diff)
    end

    def match_amount?(received_amount)
      received_amount.to_d == invoice.amount.to_d
    end

    def match_transaction_time_threshold?(time_diff)
      time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
    end

    def find_token?(transaction)
      amount = parse_tokens_amount(transaction)
      transaction_created_at = timestamp_in_utc(transaction['timestamp'])
      invoice_created_at = invoice.created_at.utc

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      invoice_created_at < transaction_created_at && match_by_amount_and_time?(amount, time_diff) && match_by_contract_address?(transaction)
    end

    def match_by_contract_address?(transaction)
      transaction['fungibleTokens'].first['type'].tr('-','') == wallet.payment_system.token_network.upcase
    end

    def parse_received_amount(transaction)
      recipient = transaction['recipients'].find { |recipient| recipient['address'].include?(invoice.address) }
      recipient ? recipient['amount'] : 0
    end

    def parse_tokens_amount(transaction)
      tokens = transaction['fungibleTokens'].first
      tokens['recipient'] == invoice.address ? tokens['amount'] : 0
    end

    def timestamp_in_utc(timestamp)
      DateTime.strptime(timestamp.to_s,'%s').utc
    end
  end
end
