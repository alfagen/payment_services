# frozen_string_literal: true

class PaymentServices::Paylama
  class CurrencyRepository
    CURRENCY_TO_PROVIDER_CURRENCY = { RUB: 1, USD: 2, KZT: 3, EUR: 4 }.stringify_keys.freeze

    include Virtus.model

    attribute :kassa_currency, Object

    def self.build_from(kassa_currency:)
      new(
        kassa_currency: kassa_currency,
      )
    end

    def provider_currency
      CURRENCY_TO_PROVIDER_CURRENCY[kassa_currency.to_s]
    end
  end
end
