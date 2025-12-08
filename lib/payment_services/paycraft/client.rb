# frozen_string_literal: true


module PaymentServices
  class Paycraft
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://p2p-lk.paycraft.pro/api/proxy/19/transaction/service'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/create_pay_in",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/payin_status",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def create_payout(params:)
        safely_parse http_request(
          url: "#{API_URL}/create_payout",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      def payout(params:)
        safely_parse http_request(
          url: "#{API_URL}/payout_status",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_headers(signature:)
        {
          'ApiPublic' => api_key,
          'Signature' => signature
        }
      end

      def build_signature(params)
        OpenSSL::HMAC.hexdigest('SHA512', secret_key, params.to_json)
      end
    end
  end
end
