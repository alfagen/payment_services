# frozen_string_literal: true

class PaymentServices::BlockIo
  class Transaction
    include Virtus.model

    CONFIRMATIONS_FOR_COMPLETE = 1

    attribute :id, String
    attribute :confirmations, Integer
    attribute :created_at, DateTime
    attribute :total_spend, Float
    attribute :source, String

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction['txid'],
        confirmations: raw_transaction['confirmations'],
        created_at: timestamp_in_datetime_utc(raw_transaction['time']),
        total_spend: parse_total_spend(raw_transaction),
        source: raw_transaction
      )
    end

    def to_s
      attributes.to_s
    end

    def successful?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end

    private

    def timestamp_in_datetime_utc(timestamp)
      Time.at(timestamp).to_datetime.utc
    end

    def parse_total_spend(raw_transaction)
      raw_transaction['total_amount_sent']&.to_f || 0
    end
  end
end
