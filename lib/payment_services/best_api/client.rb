# frozen_string_literal: true

class PaymentServices::BestApi
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://nash-c6dd440834c0.herokuapp.com/api'

    def initialize(api_key:)
      @api_key = api_key
    end

    def income_wallet(amount:, currency:)
      safely_parse(http_request(
        url: "#{API_URL}/get_card/client/#{api_key}/amount/#{amount}/currency/#{currency}/niche/auto",
        method: :GET,
        headers: {}
      )).first
    end

    private

    attr_reader :api_key
  end
end
