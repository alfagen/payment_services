# frozen_string_literal: true

class PaymentServices::MasterProcessing
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://masterprocessingvip.ru/api/payment'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/generate_p2p_v3",
        method: :POST,
        body: params.to_json,
        headers: build_headers(build_signature(params))
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature)
      {
        'Content-Type'  => 'application/json',
        'API-Key'       => api_key,
        'Signature'     => signature
      }
    end

    def build_signature(request_body)
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, request_body.to_json)
    end
  end
end
