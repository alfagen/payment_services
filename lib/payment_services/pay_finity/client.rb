# frozen_string_literal: true

class PaymentServices::PayFinity
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://pay-finity.com'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      url = '/api/v1/payment'
      params_as_json = params.to_json
      safely_parse http_request(
        url: "#{API_URL}#{url}",
        method: :POST,
        body: params_as_json,
        headers: build_headers(signature: build_signature(url, params_as_json))
      )
    end

    def transaction(deposit_id:)
      url = '/api/v1/account/transaction'
      params = "trackerID=#{deposit_id}"
      safely_parse http_request(
        url: "#{API_URL}#{url}?#{params}",
        method: :GET,
        headers: build_headers(signature: build_signature(url, params))
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature:)
      {
        'Content-Type' => 'application/json',
        'Public-Key'   => "#{api_key}",
        'Expires'      => (Time.now.utc + 300).to_i,
        'Signature'    => signature
      }
    end

    def build_signature(url, params)
      sign_string = "#{url}#{params}"
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), secret_key, sign_string)
    end
  end
end
