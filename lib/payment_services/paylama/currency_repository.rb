# frozen_string_literal: true

class PaymentServices::Paylama
  class CurrencyRepository
    CURRENCY_TO_PROVIDER_CURRENCY = { RUB: 1, USD: 2, KZT: 3, EUR: 4, DSH: 'DASH' }.stringify_keys.freeze
    TOKEN_NETWORK_TO_PROVIDER_CURRENCY = { erc20: 'USDT', trc20: 'USDTTRC', bep20: 'USDTBEP', bep2: 'BNB' }.stringify_keys.freeze
    BNB_BEP20_PROVIDER_CURRENCY = 'BNB20'
    BNB_BEP20_TOKEN_NETWORK = 'bep20'

    include Virtus.model

    attribute :kassa_currency, Object
    attribute :token_network, String

    def self.build_from(kassa_currency:, token_network: nil)
      new(
        kassa_currency: kassa_currency,
        token_network: token_network
      )
    end

    def provider_fiat_currency
      CURRENCY_TO_PROVIDER_CURRENCY[kassa_currency.to_s]
    end

    def provider_crypto_currency
      currency = kassa_currency.to_s.injuiry
      return BNB_BEP20_PROVIDER_CURRENCY if currency.BNB? && token_network == BNB_BEP20_TOKEN_NETWORK
      return TOKEN_NETWORK_TO_PROVIDER_CRYPTO_CURRENCY[token_network] if token_network.present?

      CURRENCY_TO_PROVIDER_CURRENCY[currency] || currency
    end
  end
end
