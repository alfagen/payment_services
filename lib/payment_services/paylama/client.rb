# frozen_string_literal: true

module PaymentServices
  class Paylama
    class Client < ::PaymentServices::Base::Client
      FIAT_API_URL = 'https://admin.paylama.io/api/api/payment'
      CRYPTO_API_URL = 'https://admin.paylama.io/api/crypto'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_fiat_invoice(params:)
        safely_parse http_request(
          url: "#{FIAT_API_URL}/generate_invoice_h2h",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def process_fiat_payout(params:)
        safely_parse http_request(
          url: "#{FIAT_API_URL}/generate_withdraw",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def create_p2p_invoice(params:)
        safely_parse http_request(
          url: "#{FIAT_API_URL}/generate_invoice_card_transfer",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def create_crypto_address(currency:)
        params = { currency: currency }
        safely_parse http_request(
          url: "#{CRYPTO_API_URL}/payment",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def process_crypto_payout(params:)
        safely_parse http_request(
          url: "#{CRYPTO_API_URL}/payout",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def payment_status(payment_id:, type:)
        params = {
          externalID: payment_id,
          orderType: type
        }

        safely_parse http_request(
          url: "#{FIAT_API_URL}/get_order_details",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_signature(params)
        OpenSSL::HMAC.hexdigest('SHA512', secret_key, params.to_json)
      end

      def build_headers(signature:)
        {
          'Content-Type'  => 'application/json',
          'API-Key'       => api_key,
          'Signature'     => signature
        }
      end
    end
  end
end
