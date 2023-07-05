# frozen_string_literal: true

class PaymentServices::OneCrypto
  class Transaction
    SUCCESS_PROVIDER_STATE  = 'SUCCESS'
    FAILED_PROVIDER_STATE   = 'ERROR'

    include Virtus.model

    attribute :amount, Float
    attribute :currency, String
    attribute :status, String
    attribute :transaction_id, String
    attribute :source, Hash

    def self.build_from(raw_transaction)
      new(
        amount: raw_transaction['amount'].to_f,
        currency: raw_transaction['token'],
        status: raw_transaction['status'],
        transaction_id: raw_transaction['hash'],
        source: raw_transaction
      )
    end

    def to_s
      source.to_s
    end

    def valid_amount?(payout_amount, payout_currency)
      (amount == 0 || amount == payout_amount) && currency == payout_currency
    end

    def succeed?
      status == SUCCESS_PROVIDER_STATE
    end

    def failed?
      status == FAILED_PROVIDER_STATE
    end
  end
end
