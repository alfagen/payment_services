# frozen_string_literal: true

module PaymentServices
  class MerchantAlikassa
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://api-merchant.alikassa.com/v1'
      PAYMENTS_PRIVATE_KEY_FILE_PATH = 'config/alikassa_payments_privatekey.pem'
      PAYOUTS_PRIVATE_KEY_FILE_PATH = 'config/alikassa_payouts_privatekey.pem'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_invoice(params:)
        safely_parse http_request(
          url: "#{API_URL}/payment",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params, PAYMENTS_PRIVATE_KEY_FILE_PATH))
        )
      end

      def invoice_transaction(deposit_id:)
        params = { id: deposit_id }
        safely_parse http_request(
          url: "#{API_URL}/payment/status",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params, PAYMENTS_PRIVATE_KEY_FILE_PATH))
        )
      end

      def create_payout(params:)
        safely_parse http_request(
          url: "#{API_URL}/payout",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params, PAYOUTS_PRIVATE_KEY_FILE_PATH))
        )
      end

      def payout_transaction(payout_id:)
        params = { id: payout_id }
        safely_parse http_request(
          url: "#{API_URL}/payout/status",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params, PAYOUTS_PRIVATE_KEY_FILE_PATH))
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_headers(signature:)
        {
          'Content-Type' => 'application/json',
          'Account' => "#{api_key}",
          'Sign' => signature
        }
      end

      def build_signature(params, private_key_file_path)
        private_key = OpenSSL::PKey::read(File.read(private_key_file_path), secret_key)
        signature = private_key.sign(OpenSSL::Digest::SHA1.new, params.to_json)
        Base64.encode64(signature).gsub(/\n/, '')
      end
    end
  end
end
