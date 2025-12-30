# frozen_string_literal: true

module PaymentServices
  class PayForUH2h
    class Client < ::PaymentServices::PayForU::Client
      def update_invoice(deposit_id:, params:)
        safely_parse http_request(
          url: "#{API_URL}/shop/orders/#{deposit_id}",
          method: :PATCH,
          body: params.to_json,
          headers: build_headers
        )
      end

      def start_payment(deposit_id:)
        safely_parse http_request(
          url: "#{API_URL}/shop/orders/#{deposit_id}/start-payment",
          method: :POST,
          body: {}.to_json,
          headers: build_headers
        )
      end

      def confirm_payment(deposit_id:)
        safely_parse http_request(
          url: "#{API_URL}/shop/orders/#{deposit_id}/confirm-payment",
          method: :POST,
          body: {}.to_json,
          headers: build_headers
        )
      end
    end
  end
end
