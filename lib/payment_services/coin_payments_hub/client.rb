# frozen_string_literal: true

require 'openssl'
require 'digest'
require 'base64'

class PaymentServices::CoinPaymentsHub
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.coinpaymentshub.com/v1'

    def initialize(api_key:)
      @api_key = api_key
    end

    def create_invoice(params:)
      logger.info "params: #{params.to_json}"
      safely_parse http_request(
        url: "#{API_URL}/invoice/create",
        method: :POST,
        body: { payload: sign_params(params) }.to_json,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key

    def build_headers
      {
        'Content-Type'  => 'application/json'
      }
    end

    def sign_params(params)
      md5_api_key = Digest::MD5.hexdigest(api_key)
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.encrypt
      iv = cipher.iv = cipher.random_iv
      cipher.key = md5_api_key

      value = cipher.update(params.to_json) + cipher.final
      value = Base64.encode64(value).chomp
      iv = Base64.encode64(iv).chomp
      mac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), md5_api_key, iv + value)
      tag = ''

      json_string = { iv: iv, value: value, mac: mac, tag: tag }.to_json
      Base64.encode64(json_string).gsub(/\n/, '')
    end
  end
end