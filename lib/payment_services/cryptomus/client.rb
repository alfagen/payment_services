# frozen_string_literal: true

class PaymentServices::Cryptomus
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.cryptomus.com/v1'

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

    def transaction(params:)
      safely_parse http_request(
        url: "#{API_URL}/payment/info",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params = {})
      Digest::MD5.hexdigest(Base64.encode64(params.to_json.gsub('/', '\/') + secret_key).gsub(/\n/, ''))
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
