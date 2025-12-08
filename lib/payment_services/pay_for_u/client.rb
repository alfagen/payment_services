# frozen_string_literal: true


module PaymentServices
  class PayForU
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://payforu.cash/public/api/v1'

      def initialize(api_key:)
        @api_key = api_key
      end

      def create_invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/shop/orders",
          method: :POST,
          body: params.to_json,
          headers: build_headers
        )
      end

      def transaction(deposit_id:)
        safely_parse http_request(
          url: "#{API_URL}/shop/orders/#{deposit_id}",
          method: :GET,
          headers: build_headers
        )
      end

      private

      attr_reader :api_key

      def build_headers
        {
          'Content-Type'  => 'application/json',
          'Authorization' => "Bearer #{api_key}"
        }
      end
    end
  end
end
