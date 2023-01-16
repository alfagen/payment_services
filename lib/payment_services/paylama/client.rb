# frozen_string_literal: true

class PaymentServices::Paylama
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://admin.paylama.io/api/api/payment'

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
