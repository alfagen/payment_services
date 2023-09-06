# frozen_string_literal: true

class PaymentServices::BestApi
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://bestapi.cc/api'

    def initialize(api_key:)
      @api_key = api_key
    end

    def create_invoice(amount:, currency:)
      safely_parse(http_request(
        url: "#{API_URL}/get_card/client/#{api_key}/amount/#{amount}/currency/#{currency}",
        method: :GET,
        headers: {}
      )).first
    end

    def transaction(deposit_id:)
      safely_parse(http_request(
        url: "#{API_URL}/check_trade/trade/#{deposit_id}",
        method: :GET,
        headers: {}
      )).first
    end

    private

    attr_reader :api_key
  end
end
