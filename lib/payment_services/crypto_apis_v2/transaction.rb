# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Transaction
    SUCCESS_PAYOUT_STATUS = 'tesSUCCESS'

    include Virtus.model

    attribute :id, String
    attribute :fee, Float
    attribute :source, String

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction['transactionHash'],
        fee: raw_transaction['fee']['amount'].to_f,
        source: raw_transaction
      )
    end

    def confirmed?
      (source['isConfirmed'] || source['status'] == SUCCESS_PAYOUT_STATUS) ? true : false
    end
  end
end
