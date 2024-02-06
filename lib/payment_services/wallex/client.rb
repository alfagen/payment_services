# frozen_string_literal: true

class PaymentServices::Wallex
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://wallex.online/exchange'
    MERCHANT_ID = 286

    def initialize(api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: "#{API_URL}/create_deal_v2/#{MERCHANT_ID}",
        method: :POST,
        body: params.merge(sign: signature(params: params)).to_json,
        headers: build_headers
      )
    end

    def transaction(deposit_id:)
      safely_parse http_request(
        url: "#{API_URL}/get?id=#{deposit_id}",
        method: :GET,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers
      {
        'Content-Type' => 'application/json',
        'X-Api-Key' => api_key
      }
    end

    def signature(params:)
      Digest::SHA1.hexdigest(params.values.join + secret_key)
    end
  end
end
