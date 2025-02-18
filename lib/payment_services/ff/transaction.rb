# frozen_string_literal: true

class PaymentServices::Ff
  class Transaction
    SUCCESS_INCOME_PROVIDER_STATE   = 'EXCHANGE'
    SUCCESS_OUTCOME_PROVIDER_STATE  = 'DONE'
    FAILED_PROVIDER_STATE = 'EXPIRED'

    include Virtus.model

    attribute :id, String
    attribute :status, String
    attribute :source, Hash

    def self.build_from(raw_transaction, direction: :from)
      new(
        status: raw_transaction['status'],
        id: raw_transaction[direction.to_s]['tx']['id'],
        source: raw_transaction
      )
    end

    def to_s
      source.to_s
    end

    def income_succeed?
      status == SUCCESS_INCOME_PROVIDER_STATE
    end

    def outcome_succeed?
      status == SUCCESS_OUTCOME_PROVIDER_STATE
    end

    def failed?
      status == FAILED_PROVIDER_STATE
    end
  end
end
