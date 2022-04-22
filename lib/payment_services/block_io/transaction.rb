# frozen_string_literal: true

class PaymentServices::BlockIo
  class Transaction
    include Virtus.model

    CONFIRMATIONS_FOR_COMPLETE = 1

    attribute :id, String
    attribute :confirmations, Integer
    attribute :source, String

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction['txid'],
        confirmations: raw_transaction['confirmations'],
        source: raw_transaction
      )
    end

    def to_s
      source.to_s
    end

    def successful?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end

    def created_at
      Time.at(source['time']).to_datetime.utc
    end

    def total_spend
      source['total_amount_sent'].to_f
    end
  end
end
