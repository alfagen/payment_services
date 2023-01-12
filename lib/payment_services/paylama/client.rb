# frozen_string_literal: true

class PaymentServices::Paylama
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://sandbox.paylama.io/api/api/payment'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def generate_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/generate_invoice_h2h",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params)
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, params.to_json)
    end

    def build_headers(signature:)
      {
        'Content-Type'  => 'application/json',
        'API-Key'       => api_key,
        'Signature'     => signature
      }
    end
  end
end
