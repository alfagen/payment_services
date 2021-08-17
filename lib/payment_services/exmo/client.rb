# frozen_string_literal: true

class PaymentServices::Exmo
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.exmo.com/v1.1'

    def initialize(public_key:, secret_key:)
      @public_key = public_key
      @secret_key = secret_key
    end

    def create_payout(params:)
      body = URI.encode_www_form(params.merge(nonce: nonce))
      safely_parse http_request(
        url: "#{API_URL}/withdraw_crypt",
        method: :POST,
        body: body,
        headers: build_headers(build_signature(body))
      )
    end

    def wallet_operations(currency:, type:)
      body = URI.encode_www_form({
        currency: currency,
        type: type,
        nonce: nonce
      })
      safely_parse http_request(
        url: "#{API_URL}/wallet_operations",
        method: :POST,
        body: body,
        headers: build_headers(build_signature(body))
      )
    end

    private

    attr_reader :public_key, :secret_key

    def build_headers(signature)
      {
        'Content-Type'  => 'application/x-www-form-urlencoded',
        'Key' => public_key,
        'Sign' => signature
      }
    end

    def nonce
      Time.now.strftime("%s%6N")
    end

    def build_signature(request_body)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), secret_key, request_body)
    end
  end
end
