# frozen_string_literal: true

module PaymentServices
  class Erapay
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://erapay.ru/api'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/createOrder",
          method: :POST,
          body: URI.encode_www_form(params.merge(token: api_key, shop_id: secret_key)),
          headers: build_headers
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_headers
        {
          'Content-Type' => 'application/x-www-form-urlencoded'
        }
      end
    end
  end
end
