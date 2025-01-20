# frozen_string_literal: true

class PaymentServices::FireKassa
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://admin.vanilapay.com/api/v2'

    def initialize(api_key:)
      @api_key = api_key
    end

    def create_card_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/deposit/card",
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )
    end

    def create_sbp_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/deposit/sbp-a",
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )
    end

    def transaction(transaction_id:)
      safely_parse http_request(
        url: "#{API_URL}/transactions/#{transaction_id}",
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
