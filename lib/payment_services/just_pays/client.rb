# frozen_string_literal: true

class PaymentServices::JustPays
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://merchant-api.just-pays.com/api'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/payment_url",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def transactions
      safely_parse http_request(
        url: "#{API_URL}/order_history",
        method: :POST,
        body: {}.to_json,
        headers: build_headers(signature: build_signature)
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params: {})
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, params.to_json)
    end

    def build_headers(signature:)
      {
        'Content-Type' => 'application/json',
        'X-API-Key'    => api_key,
        'X-API-Sign'   => signature
      }
    end
  end
end
