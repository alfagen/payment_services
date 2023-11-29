# frozen_string_literal: true

class PaymentServices::CoinPaymentsHub
  class Transaction
    SUCCESS_PROVIDER_STATE  = 'success'
    FAILED_PROVIDER_STATE   = 'cancel'

    include Virtus.model

    attribute :amount, Float
    attribute :currency, String
    attribute :status, String
    attribute :source, Hash

    def self.build_from(raw_transaction)
      new(
        amount: raw_transaction['paid_amount'].to_f,
        currency: raw_transaction['currency_symbol'],
        status: raw_transaction['status'],
        source: raw_transaction
      )
    end

    def to_s
      source.to_s
    end

    def valid_amount?(payout_amount, payout_currency)
      (amount.zero? || amount == payout_amount) && currency == payout_currency
    end

    def succeed?
      status == SUCCESS_PROVIDER_STATE
    end

    def failed?
      status == FAILED_PROVIDER_STATE
    end
  end
end
