# frozen_string_literal: true

require_relative 'transaction'
require_relative 'blockchain'

class PaymentServices::Blockchair
  class TransactionMatcher
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    ETC_TIME_THRESHOLD = 20.seconds
    BASIC_TIME_COUNTDOWN = 1.minute
    AMOUNT_DIVIDER = 1e+8
    ETH_AMOUNT_DIVIDER = 1e+18
    CARDANO_AMOUNT_DIVIDER = 1e+6

    def initialize(invoice:, transactions:)
      @invoice = invoice
      @transactions = transactions
    end

    def matched_transaction
      if blockchain.cardano?
        raw_transaction = transactions.find { |transaction| match_cardano_transaction?(transaction) }
        build_transaction(id: raw_transaction['ctbId'], created_at: timestamp_in_utc(raw_transaction['ctbTimeIssued']), source: raw_transaction) if raw_transaction
      elsif blockchain.stellar?
        raw_transaction = transactions.find { |transaction| match_stellar_transaction?(transaction) }
        build_transaction(id: raw_transaction['transaction_hash'], created_at: datetime_string_in_utc(raw_transaction['created_at']), source: raw_transaction) if raw_transaction
      else
        raw_transaction = transactions.find { |transaction| match_default_transaction?(transaction) }
        build_transaction(id: raw_transaction['transaction_hash'], created_at: datetime_string_in_utc(raw_transaction['time']), source: raw_transaction) if raw_transaction
      end
    end

    private

    attr_reader :invoice, :transactions

    def blockchain
      @blockchain ||= Blockchain.new(currency: invoice.order.income_wallet.currency.to_s.downcase)
    end

    def build_transaction(id:, created_at:, source:)
      Transaction.build_from(raw_transaction: { transaction_hash: id, created_at: created_at, source: source })
    end

    def match_cardano_transaction?(transaction)
      transaction_created_at = timestamp_in_utc(transaction['ctbTimeIssued'])
      invoice_created_at = invoice.created_at.utc
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      transaction['ctbOutputs'].each do |output|
        return true if match_by_output_and_time?(output, time_diff)
      end

      false
    end

    def match_stellar_transaction?(transaction)
      transaction_created_at = datetime_string_in_utc(transaction['created_at'])
      invoice_created_at = invoice.created_at.utc
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      match_by_amount_and_time?(transaction['amount'], time_diff)
    end

    def match_default_transaction?(transaction)
      amount = transaction['value'].to_f / amount_divider
      transaction_created_at = datetime_string_in_utc(transaction['time'])
      invoice_created_at = invoice.created_at.utc
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      match_by_amount_and_time?(amount, time_diff)
    end

    def match_by_output_and_time?(output, time_diff)
      amount = output['ctaAmount']['getCoin'].to_f / amount_divider
      match_by_amount_and_time?(amount, time_diff) && output['ctaAddress'] == invoice.address
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

    def datetime_string_in_utc(datetime_string)
      DateTime.parse(datetime_string).utc
    end

    def timestamp_in_utc(timestamp)
      Time.at(timestamp).to_datetime.utc
    end

    def amount_divider
      if blockchain.ethereum?
        ETH_AMOUNT_DIVIDER
      elsif blockchain.cardano?
        CARDANO_AMOUNT_DIVIDER
      else
        AMOUNT_DIVIDER
      end
    end
  end
end
