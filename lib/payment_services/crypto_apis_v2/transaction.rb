# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Transaction
    SUCCESS_PAYOUT_STATUS = 'tesSUCCESS'

    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :currency, String
    attribute :source, Hash

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction[:transaction_hash],
        created_at: raw_transaction[:created_at],
        currency: raw_transaction[:currency],
        source: raw_transaction[:source]
      )
    end

    def to_s
      source.to_s
    end

    def confirmed?
      send("#{blockchain}_transaction_confirmed?")
    end

    private

    def method_missing(method_name)
      super unless method_name.end_with?('_transaction_confirmed?')

      generic_transaction_confirmed?
    end

    def generic_transaction_confirmed?
      source['isConfirmed']
    end

    def xrp_transaction_confirmed?
      source['status'] == SUCCESS_PAYOUT_STATUS
    end

    def bnb_transaction_confirmed?
      source['status'].inquiry.confirmed?
    end

    def usdt_transaction_confirmed?
      source['status'].inquiry.confirmed?
    end
  end
end
