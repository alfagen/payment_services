# frozen_string_literal: true

class PaymentServices::OneCrypto
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://apiv2.expay.cash/api/transaction'
    MERCHANT_ID = 'kassa.cc'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/create/in",
        method: :POST,
        body: params.merge(client_merchant_id: MERCHANT_ID).to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def create_payout(params:)
      safely_parse http_request(
        url: "#{API_URL}/create/out",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def transaction(tracker_id:)
      params = { tracker_id: tracker_id }
      safely_parse(http_request(
        url: "#{API_URL}/get",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      ))['transaction']
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature:)
      {
        'Content-Type'  => 'application/json',
        'ApiPublic'     => api_key,
        'TimeStamp'     => timestamp_string,
        'Signature'     => signature
      }
    end

    def build_signature(params)
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, timestamp_string + params.to_json)
    end

    def timestamp_string
      @timestamp_string ||= Time.now.to_i.to_s
    end
  end
end
