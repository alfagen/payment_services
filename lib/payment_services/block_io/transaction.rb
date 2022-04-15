# frozen_string_literal: true

class PaymentServices::BlockIo
  class Transaction
    include Virtus.model

    attribute :transaction_id, String
    attribute :confirmations, Integer
    attribute :transaction_created_at, DateTime
    attribute :total_spend, Float

    def self.build_from(raw_transaction:)
      new(
        transaction_id: raw_transaction['txid'],
        confirmations: raw_transaction['confirmations'],
        transaction_created_at: Time.at(raw_transaction['time']).to_datetime.utc,
        total_spend: raw_transaction['total_amount_sent'].to_f
      )
    end

    def to_s
      "txid: #{transaction_id}, created_at: #{transaction_created_at}, confirmations: #{confirmations}"
    end
  end
end
