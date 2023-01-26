# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Transaction
    SUCCESS_GENERIC_TRANSACTION_STATE = 'Succeed'
    FAILED_TRANSACTION_STATE = 'Failed'

    include Virtus.model

    attribute :currency, String
    attribute :status, String
    attribute :fee, Float
    attribute :created_at, DateTime
    attribute :source, Hash

    def self.build_from(currency:, status:, fee:, created_at:, source:)
      new(
        currency: currency,
        status: status,
        fee: fee,
        created_at: created_at,
        source: source
      )
    end

    def to_s
      source.to_s
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

      generic_transaction_succeed?
    end

    def generic_transaction_succeed?
      status == SUCCESS_GENERIC_TRANSACTION_STATE
    end
  end
end
