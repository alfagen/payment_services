# frozen_string_literal: true

require_relative 'transaction'
require_relative 'blockchain'

class PaymentServices::Blockchair
  class TransactionMatcher
    AMOUNT_DIVIDER = 1e+8
    ETH_AMOUNT_DIVIDER = 1e+18
    CARDANO_AMOUNT_DIVIDER = 1e+6
    XRP_AMOUNT_DIVIDER = 1e+6
    RIPPLE_AFTER_UNIX_EPOCH = 946684800

    def initialize(invoice:, transactions:)
      @invoice = invoice
      @transactions = transactions
    end

    def perform
      send("match_#{blockchain.name}_transaction")
    end

    private

    attr_reader :invoice, :transactions

    delegate :created_at, :memo, to: :invoice, prefix: true

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

    def match_ripple_transaction
      raw_transaction = transactions.find { |transaction| match_ripple_transaction?(transaction) }
      build_transaction(id: raw_transaction['tx']['hash'], created_at: timestamp_in_utc(raw_transaction['tx']['date'] + RIPPLE_AFTER_UNIX_EPOCH), source: raw_transaction) if raw_transaction
    end

    def match_eos_transaction
      raw_transaction = transactions.find { |transaction| match_eos_transaction?(transaction) }
      build_transaction(id: raw_transaction['hash'], created_at: datetime_string_in_utc(raw_transaction['block_time']), source: raw_transaction) if raw_transaction
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

      invoice_created_at.utc < transaction_created_at && transaction['ctbOutputs'].any?(&method(:match_by_output?))
    end

    def match_stellar_transaction?(transaction)
      amount = transaction['amount']
      transaction_created_at = datetime_string_in_utc(transaction['created_at'])

      invoice_created_at.utc < transaction_created_at && match_amount?(amount)
    end

    def match_default_transaction?(transaction)
      amount = transaction['value'].to_f / amount_divider
      transaction_created_at = datetime_string_in_utc(transaction['time'])

      invoice_created_at.utc < transaction_created_at && match_amount?(amount)
    end

    def match_ripple_transaction?(transaction)
      transaction_info = transaction['tx']
      amount = transaction_info['Amount'].to_f / amount_divider
      transaction_created_at = timestamp_in_utc(transaction_info['date'] + RIPPLE_AFTER_UNIX_EPOCH)

      invoice_created_at.utc < transaction_created_at && match_amount?(amount) && match_tag?(transaction_info['DestinationTag'])
    end

    def match_tag?(tag)
      invoice_memo.present? ? invoice_memo == tag : true
    end

    def match_eos_transaction?(transaction)
      transaction_created_at = datetime_string_in_utc(raw_transaction['block_time'])
      amount_data = transaction['action_trace']['act']['data']
      invoice_created_at.utc < transaction_created_at && match_eos_amount?(amount_data)
    end

    def match_eos_amount?(amount_data)
      amount, currency = amount_data['quantity'].split
      match_amount?(amount) && currency == 'EOS'
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
      elsif blockchain.ripple?
        XRP_AMOUNT_DIVIDER
      else
        AMOUNT_DIVIDER
      end
    end
  end
end
