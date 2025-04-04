# frozen_string_literal: true

class PaymentServices::Cryptomus
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.heleket.com/v1'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/payment",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def create_payout(params:)
      safely_parse http_request(
        url: "#{API_URL}/payout",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/payment/info",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def payout(params:)
      safely_parse http_request(
        url: "#{API_URL}/payout/info",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def fee
      safely_parse http_request(
        url: "#{API_URL}/payout/services",
        method: :POST,
        body: {}.to_json,
        headers: build_headers(signature: build_signature)
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params = {})
      Digest::MD5.hexdigest(Base64.encode64(params.to_json).gsub(/\n/, '') + secret_key)
    end

    def build_headers(signature:)
      {
        'merchant'     => api_key,
        'sign'         => signature,
        'Content-Type' => 'application/json'
      }
    end
  end
end
