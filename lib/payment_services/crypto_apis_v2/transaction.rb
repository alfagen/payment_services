# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Transaction
    SUCCESS_XRP_STATUS = 'tesSUCCESS'

    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :currency, String
    attribute :source, Hash

    def self.build_from(transaction_hash:, created_at:, currency:, source:)
      new(
        id: transaction_hash,
        created_at: created_at,
        currency: currency,
        source: source
      )
    end

    def to_s
      source.to_s
    end

    def confirmed?
      send("#{currency}_transaction_confirmed?")
    end

    def fee
      source.dig('fee', 'amount')
    end

    private

    def method_missing(method_name)
      super unless method_name.end_with?('_transaction_confirmed?')

      generic_transaction_confirmed?
    end

    def generic_transaction_confirmed?
      source['minedInBlockHeight'] > 0
    end

    def xrp_transaction_confirmed?
      status == SUCCESS_XRP_STATUS
    end

    def bnb_transaction_confirmed?
      source['isConfirmed']
    end

    def usdt_transaction_confirmed?
      source['isConfirmed']
    end

    def status
      source['status'].inquiry
    end
  end
end
