# frozen_string_literal: true

require 'base64'

class PaymentServices::MasterProcessing
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://masterprocessingvip.ru/api/payment'
    SHARED_PUBLIC_KEY = "04d08e67c1371b7201aabf03b933c23b540cce0c007a59137f50d70bb4cc5ebd860344af03a47b6bb503b05952200d264c5f8fee57d54da40cd38cb7b004c629c5"

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:, payway:)
      params.merge!(hsid: generate_hsid(params))
      safely_parse http_request(
        url: "#{API_URL}/#{invoice_endpoint(payway)}",
        method: :POST,
        body: params.to_json,
        headers: build_headers(build_signature(params))
      )
    end

    def process_payout(endpoint:, params:)
      params.merge!(HSID: generate_hsid(params))
      safely_parse http_request(
        url: "#{API_URL}/#{endpoint}",
        method: :POST,
        body: params.to_json,
        headers: build_headers(build_signature(params))
      )
    end

    def invoice_status(params:)
      safely_parse http_request(
        url: "#{API_URL}/get_invoice_order_info",
        method: :POST,
        body: params.to_json,
        headers: build_headers(build_signature(params))
      )
    end

    def payout_status(params:)
      safely_parse http_request(
        url: "#{API_URL}/get_withdraw_order_info",
        method: :POST,
        body: params.to_json,
        headers: build_headers(build_signature(params))
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature)
      {
        'Content-Type'  => 'application/json',
        'API-Key'       => api_key,
        'Signature'     => signature
      }
    end

    def generate_hsid(params)
      data = params.to_json
      public_key_bin = [SHARED_PUBLIC_KEY].pack('H*')
      group = OpenSSL::PKey::EC::Group.new("prime256v1")
      public_point  = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(public_key_bin, 2))
      key = OpenSSL::PKey::EC.new(group)
      key.generate_key!
      key.public_key = public_point

      Base64.encode64(key.dsa_sign_asn1(data))
    end

    def build_signature(request_body)
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, request_body.to_json)
    end

    def invoice_endpoint(payway)
      if payway.cardh2h? || payway.qiwih2h?
        'generate_invoice_h2h'
      else
        'generate_p2p_v3'
      end
    end
  end
end
