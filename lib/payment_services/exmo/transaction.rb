# frozen_string_literal: true

class PaymentServices::Exmo
  class Transaction
    include Virtus.model

    SUCCESSFULL_PROVIDER_STATE = 'Paid'
    FAILED_PROVIDER_STATES = %w(Cancelled Error)

    attribute :id, String
    attribute :provider_state, Integer
    attribute :source, String

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction['extra']['txid'],
        provider_state: raw_transaction['status'],
        source: raw_transaction
      )
    end

    def to_s
      source.to_s
    end

    def successful?
      provider_state == SUCCESSFULL_PROVIDER_STATE
    end

    def failed?
      FAILED_PROVIDER_STATES.include?(provider_state)
    end
  end
end
