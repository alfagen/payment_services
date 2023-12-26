# frozen_string_literal: true

class PaymentServices::XPayPro
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.xpaypro.dev/v1/merchant-api'

    def initialize(api_key:)
      @api_key = api_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/txs/p2p/invoice",
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )
    end

    def transaction(deposit_id:)
      safely_parse http_request(
        url: "#{API_URL}/txs/#{deposit_id}",
        method: :GET,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Authorization' => "Bearer #{api_key}"
      }
    end
  end
end
