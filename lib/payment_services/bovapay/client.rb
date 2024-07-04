# frozen_string_literal: true

class PaymentServices::Bovapay
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://bovatech.cc/v1'

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      params.merge!(user_uuid: api_key)
      safely_parse http_request(
        url: "#{API_URL}/p2p_transactions",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def invoice(deposit_id:)
      safely_parse http_request(
        url: "#{API_URL}/p2p_transactions/#{deposit_id}",
        method: :GET,
        headers: {}
      )
    end

    def create_payout(params:)
      params.merge!(user_uuid: api_key)
      safely_parse http_request(
        url: "#{API_URL}/mass_transactions",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def payout(withdrawal_id:)
      safely_parse http_request(
        url: "#{API_URL}/mass_transactions/#{withdrawal_id}",
        method: :GET,
        headers: {}
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers(signature:)
      {
        'Content-Type' => 'application/json',
        'Signature' => signature
      }
    end

    def build_signature(params)
      Digest::SHA1.hexdigest("#{secret_key}#{params.to_json}")
    end
  end
end
