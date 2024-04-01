# frozen_string_literal: true

class PaymentServices::Tronscan
  class Transaction
    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :source, Hash

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction[:id],
        created_at: raw_transaction[:created_at],
        source: raw_transaction[:source].deep_symbolize_keys
      )
    end

    def to_s
      source.to_s
    end

    def successful?
      source[:confirmed]
    end
  end
end
