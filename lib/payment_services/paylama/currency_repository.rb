# frozen_string_literal: true

class PaymentServices::Paylama
  class CurrencyRepository
    CURRENCY_TO_PROVIDER_CURRENCY = { RUB: 1, USD: 2, KZT: 3, EUR: 4, DSH: 'DASH' }.stringify_keys.freeze
    TOKEN_NETWORK_TO_PROVIDER_CURRENCY = { erc20: 'USDT', trc20: 'USDTTRC', bep20: 'USDTBEP', bep2: 'BNB' }.stringify_keys.freeze
    BNB_BEP20_PROVIDER_CURRENCY = 'BNB20'
    BNB_BEP20_TOKEN_NETWORK = 'bep20'

    include Virtus.model

    attribute :kassa_currency, String
    attribute :token_network, String

    def self.build_from(kassa_currency:, token_network: nil)
      new(
        kassa_currency: kassa_currency.to_s,
        token_network: token_network
      )
    end

    def fiat_currency_id
      CURRENCY_TO_PROVIDER_CURRENCY[kassa_currency]
    end

    def provider_crypto_currency
      return BNB_BEP20_PROVIDER_CURRENCY if bnb_bep20?
      return TOKEN_NETWORK_TO_PROVIDER_CURRENCY[token_network] if token_network.present?

      CURRENCY_TO_PROVIDER_CURRENCY[kassa_currency] || kassa_currency
    end

    private

    def bnb_bep20?
      kassa_currency.inquiry.BNB? && token_network == BNB_BEP20_TOKEN_NETWORK
    end
  end
end
