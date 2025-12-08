# frozen_string_literal: true

require_relative 'transaction'
require_relative 'blockchain'


module PaymentServices
  class Blockchair
    class TransactionMatcher
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
      delegate :amount_divider, to: :blockchain

      def blockchain
        @blockchain ||= Blockchain.new(currency: invoice.order.income_wallet.currency.to_s.downcase)
      end

      def build_transaction(id:, created_at:, blockchain:, source:)
        Transaction.build_from(raw_transaction: { transaction_hash: id, created_at: created_at, blockchain: blockchain, source: source })
      end

      def match_cardano_transaction
        raw_transaction = transactions.find { |transaction| match_cardano_transaction?(transaction) }
        return unless raw_transaction

        inputs = raw_transaction['ctbInputs']
        output = raw_transaction['ctbOutputs'].find { |output| output.match_by_output? }
        build_transaction(
          id: raw_transaction['ctbId'],
          created_at: timestamp_in_utc(raw_transaction['ctbTimeIssued']),
          blockchain: blockchain,
          source: raw_transaction.merge(input: most_similar_cardano_input_by(output: output, inputs: inputs))
        )
      end

      def match_stellar_transaction
        raw_transaction = transactions.find { |transaction| match_stellar_transaction?(transaction) }
        return unless raw_transaction

        build_transaction(
          id: raw_transaction['transaction_hash'],
          created_at: datetime_string_in_utc(raw_transaction['created_at']),
          blockchain: blockchain,
          source: raw_transaction
        )
      end

      def match_ripple_transaction
        raw_transaction = transactions.find { |transaction| match_ripple_transaction?(transaction) }
        return unless raw_transaction

        build_transaction(
          id: raw_transaction['tx']['hash'],
          created_at: build_ripple_time(raw_transaction['tx']['date']),
          blockchain: blockchain, 
          source: raw_transaction
        )
      end

      def match_eos_transaction
        raw_transaction = transactions.find { |transaction| match_eos_transaction?(transaction) }
        build_transaction(id: raw_transaction['trx_id'], created_at: datetime_string_in_utc(raw_transaction['block_time']), blockchain: blockchain, source: raw_transaction) if raw_transaction
      end

      def method_missing(method_name)
        super unless method_name.start_with?('match_') && method_name.end_with?('_transaction')

        raw_transaction = transactions_data.find { |transaction| match_generic_transaction?(transaction) }
        return unless raw_transaction

        build_transaction(
          id: raw_transaction['transaction_hash'],
          created_at: datetime_string_in_utc(raw_transaction['time']),
          blockchain: blockchain,
          source: raw_transaction.merge(input: most_similar_input_by(output: raw_transaction))
        )
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

      def match_generic_transaction?(transaction)
        amount = transaction['value'].to_f / amount_divider
        transaction_created_at = datetime_string_in_utc(transaction['time'])

        invoice_created_at.utc < transaction_created_at && match_amount?(amount)
      end

      def match_ripple_transaction?(transaction)
        transaction_info = transaction['tx']
        amount = transaction_info['Amount'].to_f / amount_divider
        transaction_created_at = build_ripple_time(transaction_info['date'])

        invoice_created_at.utc < transaction_created_at && match_amount?(amount) && match_tag?(transaction_info['DestinationTag'])
      end

      def match_tag?(tag)
        invoice_memo.present? ? invoice_memo == tag.to_s : true
      end

      def match_eos_transaction?(transaction)
        transaction_created_at = datetime_string_in_utc(transaction['block_time'])
        amount_data = transaction['action_trace']['act']['data']
        invoice_created_at.utc < transaction_created_at && match_eos_amount?(amount_data)
      end

      def match_eos_amount?(amount_data)
        amount, currency = amount_data['quantity'].split
        match_amount?(amount) && currency == 'EOS' && match_tag?(amount_data['memo'])
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

      def build_ripple_time(timestamp)
        timestamp_in_utc(timestamp + RIPPLE_AFTER_UNIX_EPOCH)
      end

      def transactions_data(direction: 'outputs')
        signals = []

        transactions.each do |_transaction_id, transaction|
          signals << transaction[direction]
        end

        signals.flatten
      end

      def most_similar_input_by(output:)
        inputs = transactions_data(direction: 'inputs').select { |input| input['spending_time'] == output['time'] }
        inputs.min_by { |input| (input['value'] - output['value']).abs }
      end

      def most_similar_cardano_input_by(output:, inputs:)
        inputs.min_by { |input| (input['ctaAmount']['getCoin'].to_f - output['ctaAmount']['getCoin'].to_f).abs }
      end
    end
  end
end
