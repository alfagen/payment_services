# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Transaction
    SUCCESS_PAYOUT_STATUS = 'tesSUCCESS'

    include Virtus.model

    attribute :transaction_id, String
    attribute :fee, Float
    attribute :confirmed, Boolean

    def self.build_from(raw_transaction:)
      new(
        transaction_id: raw_transaction['transactionId'],
        confirmed: confirmed_status?(raw_transaction),
        fee: raw_transaction['fee']['amount'].to_f
      )
    end

    private

    def confirmed_status?(raw_transaction)
      (raw_transaction['isConfirmed'] || raw_transaction['status'] == SUCCESS_PAYOUT_STATUS) ? true : false
    end
  end
end
