# frozen_string_literal: true

class PaymentServices::Capitalist
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.capitalist.net'
    PAYMENTS_PRIVATE_KEY_FILE_PATH = 'config/capitalist_privatekey.pem'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(batch:)
      token_response = otp_token
      token = token_response['data']['token']
      modulus_hex = token_response['data']['modulus']
      exponent_hex = token_response['data']['exponent']

      params = {
        operation: 'import_batch_advanced',
        login: api_key,
        token: token,
        encrypted_password: encrypted_password(modulus_hex, exponent_hex),
        batch: batch,
        verification_type: 'SIGNATURE',
        verification_data: sign_batch(batch)
      }
      safely_parse http_request(
        url: API_URL,
        method: :POST,
        body: URI.encode_www_form(params),
        headers: build_headers
      )
    end

    def transaction(payout_id:)
      token_response = otp_token
      token = token_response['data']['token']
      modulus_hex = token_response['data']['modulus']
      exponent_hex = token_response['data']['exponent']

      params = {
        operation: 'get_batch_info',
        login: api_key,
        token: token,
        encrypted_password: encrypted_password(modulus_hex, exponent_hex),
        batch_id: payout_id
      }
      safely_parse(http_request(
        url: API_URL,
        method: :POST,
        body: URI.encode_www_form(params),
        headers: build_headers
      )).dig('data', 'records').first
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers
      {
        'x-response-format'  => 'json'
      }
    end
  
    def otp_token
      params = {
        operation: 'get_token',
        login: api_key
      }
      safely_parse http_request(
        url: API_URL,
        method: :POST,
        body: URI.encode_www_form(params),
        headers: build_headers
      )
    end

    def encrypted_password(modulus_hex, exponent_hex)
      modulus = OpenSSL::BN.new(modulus_hex, 16)
      exponent = OpenSSL::BN.new(exponent_hex, 16)
      key = OpenSSL::PKey::RSA.new
      key.set_key(modulus, exponent, nil)

      password = key.public_encrypt(secret_key, OpenSSL::PKey::RSA::PKCS1_PADDING)
      password.unpack1('H*')
    end

    def sign_batch(batch)
      private_key = OpenSSL::PKey::RSA.new(File.read(PAYMENTS_PRIVATE_KEY_FILE_PATH))
      signature = private_key.sign(OpenSSL::Digest::SHA256.new, batch)
      Base64.strict_encode64(signature)
    end
  end
end
