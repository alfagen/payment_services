# frozen_string_literal: true

class PaymentServices::ExPay
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://apiv2.expay.cash/api/transaction'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/create/in",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params, timestamp_string), timestamp: timestamp_string)
      )
    end

    def transactions(params:)
      safely_parse http_request(
        url: "#{API_URL}/fetch",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params, timestamp_string), timestamp: timestamp_string)
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature:, timestamp:)
      {
        'Content-Type'  => 'application/json',
        'ApiPublic'     => api_key,
        'TimeStamp'     => timestamp,
        'Signature'     => signature
      }
    end

    def build_signature(params, timestamp)
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, timestamp + params.to_json)
    end

    def timestamp_string
      @timestamp_string ||= Time.now.to_i.to_s
    end
  end
end
