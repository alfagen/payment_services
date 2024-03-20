# frozen_string_literal: true

class PaymentServices::Tronscan
  class Transaction
    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :currency, String
    attribute :source, Hash

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction[:id],
        created_at: raw_transaction[:created_at],
        currency: currency,
        source: raw_transaction[:source].deep_symbolize_keys
      )
    end

    def to_s
      source.to_s
    end

    def successful?
      send("#{currency}_transaction_confirmed?")
    end

    private

    def trx_transaction_confirmed?
      source[:confirmed] == 1
    end

    def usdt_transaction_confirmed?
      source[:confirmed]
    end
  end
end
