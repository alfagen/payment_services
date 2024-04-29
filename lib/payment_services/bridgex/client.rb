# frozen_string_literal: true

class PaymentServices::Bridgex
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://p2p-api.bridgex.ai/v1'
    TEST_MODE = 'yes'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      params.merge!(project: api_key, test_mode: TEST_MODE)
      safely_parse http_request(
        url: "#{API_URL}/payment/create",
        method: :POST,
        body: params.merge(sign: build_signature(params)).to_json,
        headers: build_headers
      )
    end

    def transaction(deposit_id:)
      params = { project: api_key, order_id: deposit_id, test_mode: TEST_MODE }
      safely_parse http_request(
        url: "#{API_URL}/payment/status",
        method: :POST,
        body: params.merge(sign: build_signature(params)).to_json,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, params.to_json)
    end

    def build_headers
      {
        'Content-Type'  => 'application/json'
      }
    end
  end
end
