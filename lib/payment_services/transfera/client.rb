# frozen_string_literal: true

module PaymentServices
  class Transfera
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://api.transfera.io'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/integrations/ru/transactions/new/",
          method: :POST,
          body: params.merge(merchantToken: api_key, hmacHash: signature(params)).to_json,
          headers: build_headers
        )
      end

      def transaction(transaction_id:)
        safely_parse http_request(
          url: "#{API_URL}/integrations/ru/transactions/#{transaction_id}",
          method: :GET,
          headers: build_headers
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_headers
        {
          'Content-Type' => 'application/json'
        }
      end

      def signature(params)
        OpenSSL::HMAC.hexdigest('SHA512', secret_key, [params[:amount], params[:currency], api_key].join('::'))
      end
    end
  end
end
