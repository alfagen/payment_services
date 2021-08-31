# frozen_string_literal: true

class PaymentServices::Binance
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.binance.com'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def deposit_history(currency:)
      body = { currency: currency, timestamp: Time.now.to_i * 1000 }.to_query
      body += "&signature=#{build_signature(body)}"
      url = "#{API_URL}/sapi/v1/capital/deposit/hisrec?#{body}"
      safely_parse http_request(
        url: url,
        method: :GET,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers
      {
        'Content-Type'  => 'application/x-www-form-urlencoded',
        'X-MBX-APIKEY'  => api_key
      }
    end

    def build_signature(request_body)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, request_body)
    end
  end
end
