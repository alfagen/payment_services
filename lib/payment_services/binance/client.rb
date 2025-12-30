# frozen_string_literal: true

module PaymentServices
  class Binance
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://api.binance.com'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def deposit_history(currency:)
        query = build_query(params: { coin: currency })
        safely_parse http_request(
          url: "#{API_URL}/sapi/v1/capital/deposit/hisrec?#{query}",
          method: :GET,
          headers: build_headers
        )
      end

      def withdraw_history(currency:, network:)
        query = build_query(params: { coin: currency, network: network })
        safely_parse http_request(
          url: "#{API_URL}/sapi/v1/capital/withdraw/history?#{query}",
          method: :GET,
          headers: build_headers
        )
      end

      def create_payout(params:)
        query = build_query(params: params)
        safely_parse http_request(
          url: "#{API_URL}/sapi/v1/capital/withdraw/apply?#{query}",
          method: :POST,
          headers: build_headers
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_query(params:)
        query = params.merge(
          timestamp: time_now_milliseconds
        ).compact.to_query
        query += "&signature=#{build_signature(query)}"
        query
      end
    
      def time_now_milliseconds
        Time.now.to_i * 1000
      end

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
end
