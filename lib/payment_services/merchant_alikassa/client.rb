# frozen_string_literal: true

class PaymentServices::MerchantAlikassa
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api-merchant.alikassa.com/v1'
    PRIVATE_KEY_FILE_PATH = 'config/alikassa_payments_privatekey.pem'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/payment",
        method: :POST,
        body: params,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def transaction(deposit_id:)
      params = { id: deposit_id }
      safely_parse http_request(
        url: "#{API_URL}/payment/status",
        method: :POST,
        body: params,
        headers: build_headers(signature: build_signature(params))
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

    def build_signature(params)
      private_key = OpenSSL::PKey::read(File.read(PRIVATE_KEY_FILE_PATH), secret_key)
      signature = private_key.sign(OpenSSL::Digest::SHA1.new, params.to_json)
      Base64.encode64(signature).gsub(/\n/, '')
    end
  end
end
