# frozen_string_literal: true

class PaymentServices::PayForU
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://sandbox.payforu.cash/public/api/v1'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/shop/orders",
        method: :POST,
        body: build_body_signature(params),
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

    attr_reader :api_key, :secret_key

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{api_key}"
      }
    end

    def build_body_signature(params)
      sign_string = params.merge(signatureKey: secret_key).map { |key, value| "#{key}=#{value}" }.join('|')
      Digest::SHA1.hexdigest(sign_string)
    end
  end
end
