# frozen_string_literal: true

class PaymentServices::BestApi
  class Client < ::PaymentServices::Base::Client
    def initialize(api_key:, api_secret:)
      @api_key = api_key
      @api_secret = api_secret
    end

    def create_invoice(amount:, currency:)
      safely_parse(http_request(
        url: "#{base_api_url}/get_card/client/#{api_key}/amount/#{amount}/currency/#{currency}",
        method: :GET,
        headers: {}
      )).first
    end

    def transaction(deposit_id:)
      safely_parse(http_request(
        url: "#{base_api_url}/check_trade/trade/#{deposit_id}",
        method: :GET,
        headers: {}
      )).first
    end

    private

    attr_reader :api_key, :api_secret

    def base_api_url
      "https://#{api_secret}/api"
    end
  end
end
