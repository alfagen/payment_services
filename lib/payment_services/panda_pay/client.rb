# frozen_string_literal: true

class PaymentServices::PandaPay
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.pandapay24.com'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      timestamp = Time.now.utc.to_i
      params_as_json = params.to_json
      request_body = "#{timestamp}#{params_as_json}"

      safely_parse http_request(
        url: "#{API_URL}/orders",
        method: :POST,
        body: params_as_json,
        headers: build_headers(signature: build_signature(request_body), timestamp: timestamp)
      )
    end

    def invoice(deposit_id:)
      timestamp = Time.now.utc.to_i
      request_body = "#{timestamp}"

      safely_parse http_request(
        url: "#{API_URL}/orders/#{deposit_id}",
        method: :GET,
        headers: build_headers(signature: build_signature(request_body), timestamp: timestamp)
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature:, timestamp:)
      {
        'X-API-Key'    => api_key,
        'X-Signature'  => signature,
        'X-Timestamp'  => timestamp.to_s
      }
    end

    def build_signature(request_body)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, request_body)
    end
  end
end
