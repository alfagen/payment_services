# frozen_string_literal: true

module PaymentServices
  class PaylamaCrypto
    class Transaction
      SUCCESS_TRANSACTION_STATE = 'Succeed'
      FAILED_TRANSACTION_STATE = 'Failed'

      include Virtus.model

      attribute :amount, Float
      attribute :currency, String
      attribute :status, String
      attribute :fee, Float
      attribute :created_at, DateTime
      attribute :source, Hash

      def self.build_from(raw_transaction)
        new(
          amount: raw_transaction['amount'].to_f,
          currency: raw_transaction['currency'],
          status: raw_transaction['status'],
          fee: raw_transaction['fee'],
          created_at: DateTime.strptime(raw_transaction['createdAt'].to_s,'%s').utc,
          source: raw_transaction
        )
      end

      def to_s
        source.to_s
      end

      def valid_amount?(payout_amount, payout_currency)
        (amount == 0 || amount == payout_amount) && currency == payout_currency
      end

      def succeed?
        send("#{currency}_transaction_succeed?")
      end

      def failed?
        status == FAILED_TRANSACTION_STATE
      end

      private

      def method_missing(method_name)
        super unless method_name.end_with?('_transaction_succeed?')

        default_transaction_succeed?
      end

      def default_transaction_succeed?
        status == SUCCESS_TRANSACTION_STATE
      end
    end
  end
end
