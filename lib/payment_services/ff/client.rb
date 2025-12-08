# frozen_string_literal: true


module PaymentServices
  class Ff
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://ff.io/api/v2'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/create",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def transaction(params:)
        safely_parse http_request(
          url: "#{API_URL}/order",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def ccies
        safely_parse http_request(
          url: "#{API_URL}/ccies",
          method: :POST,
          body: {}.to_json,
          headers: build_headers(signature: build_signature({}))
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_headers(signature:)
        {
          'Accept'        => 'application/json',
          'X-API-KEY'     => api_key,
          'X-API-SIGN'    => signature,
          'Content-Type'  => 'application/json; charset=UTF-8'
        }
      end

      def build_signature(params)
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), secret_key, params.to_json)
      end
    end
  end
end
