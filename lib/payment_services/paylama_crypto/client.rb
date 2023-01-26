# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Client < ::PaymentServices::Paylama::Client
    CRYPTO_API_URL = 'https://admin.paylama.io/api/crypto'

    def create_crypto_address(currency:)
      params = { currency: currency }
      safely_parse http_request(
        url: "#{CRYPTO_API_URL}/payment",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def process_payout(params:)
      safely_parse http_request(
        url: "#{CRYPTO_API_URL}/payout",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end
  end
end
