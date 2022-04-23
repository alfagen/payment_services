# frozen_string_literal: true

require_relative 'transaction'
require_relative 'blockchain'

class PaymentServices::Blockchair
  class TransactionMatcher
    AMOUNT_DIVIDER = 1e+8
    ETH_AMOUNT_DIVIDER = 1e+18
    CARDANO_AMOUNT_DIVIDER = 1e+6

    def initialize(invoice:, transactions:)
      @invoice = invoice
      @transactions = transactions
    end

    def perform
      send("match_#{blockchain}_transaction")
    end

    private

    attr_reader :invoice, :transactions

    def blockchain
      @blockchain ||= Blockchain.new(currency: invoice.order.income_wallet.currency.to_s.downcase)
    end

    def build_transaction(id:, created_at:, source:)
      Transaction.build_from(raw_transaction: { transaction_hash: id, created_at: created_at, source: source })
    end

    def match_cardano_transaction
      raw_transaction = transactions.find { |transaction| match_cardano_transaction?(transaction) }
      build_transaction(id: raw_transaction['ctbId'], created_at: timestamp_in_utc(raw_transaction['ctbTimeIssued']), source: raw_transaction) if raw_transaction
    end

    def match_stellar_transaction
      raw_transaction = transactions.find { |transaction| match_stellar_transaction?(transaction) }
      build_transaction(id: raw_transaction['transaction_hash'], created_at: datetime_string_in_utc(raw_transaction['created_at']), source: raw_transaction) if raw_transaction
    end

    def method_missing(method_name)
      if method_name.start_with?('match_') && method_name.end_with?('_transaction')
        raw_transaction = transactions.find { |transaction| match_default_transaction?(transaction) }
        build_transaction(id: raw_transaction['transaction_hash'], created_at: datetime_string_in_utc(raw_transaction['time']), source: raw_transaction) if raw_transaction
      else
        super
      end
    end

    def match_cardano_transaction?(transaction)
      transaction_created_at = timestamp_in_utc(transaction['ctbTimeIssued'])
      invoice_created_at = invoice.created_at.utc

      invoice_created_at < transaction_created_at && transaction['ctbOutputs'].any?(&method(:match_by_output?))
    end

    def match_stellar_transaction?(transaction)
      amount = transaction['amount']
      transaction_created_at = datetime_string_in_utc(transaction['created_at'])
      invoice_created_at = invoice.created_at.utc

      invoice_created_at < transaction_created_at && match_amount?(amount)
    end

    def match_default_transaction?(transaction)
      amount = transaction['value'].to_f / amount_divider
      transaction_created_at = datetime_string_in_utc(transaction['time'])
      invoice_created_at = invoice.created_at.utc

      invoice_created_at < transaction_created_at && match_amount?(amount)
    end

    def match_by_output?(output)
      amount = output['ctaAmount']['getCoin'].to_f / amount_divider
      match_amount?(amount) && output['ctaAddress'] == invoice.address
    end

    def match_amount?(received_amount)
      received_amount.to_d == invoice.amount.to_d
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
