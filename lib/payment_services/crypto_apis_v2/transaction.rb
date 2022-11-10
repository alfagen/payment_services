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
      send("#{blockchain}_transaction_succeed?")
    end

    private

    def method_missing(method_name)
      super unless method_name.end_with?('_transaction_succeed?')

      generic_transaction_succeed?
    end

    def generic_transaction_succeed?
      source['isConfirmed']
    end

    def xrp_transaction_succeed?
      source['status'] == SUCCESS_PAYOUT_STATUS
    end

    def bnb_transaction_succeed?
      source['status'] == 'confirmed'
    end

    def usdt_transaction_succeed?
      source['status'] == 'confirmed'
    end
  end
end
