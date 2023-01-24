# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://admin.paylama.io/api/crypto'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_crypto_address(currency:)
      params = { currency: currency }
      safely_parse http_request(
        url: "#{API_URL}/payment",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def transactions(created_at_from:, created_at_to:, type:)
      params = {
        createdAtFrom: created_at_from,
        createdAtTo: created_at_to,
        orderType: type
      }
      safely_parse http_request(
        url: "https://admin.paylama.io/api/api/payment/fetch_orders",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def process_payout(params:)
      safely_parse http_request(
        url: "#{API_URL}/generate_withdraw",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def payment_status(payment_id:, type:)
      params = {
        externalID: payment_id,
        orderType: type
      }

      safely_parse http_request(
        url: "#{API_URL}/get_order_details",
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
