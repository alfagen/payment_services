# frozen_string_literal: true

class PaymentServices::Tronscan
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://apilist.tronscanapi.com/api'
    USDT_TRC_CONTRACT_ADDRESS = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
    CURRENCY_TO_ENDPOINT = {
      'trx'  => 'trx',
      'usdt' => 'trc20'
    }.freeze

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @currency = currency.inquiry
    end

    def transactions(address:, invoice_created_at:)
      params = { address: address, start_timestamp: invoice_created_at.to_i }.to_query
      params[:trc20Id] = USDT_TRC_CONTRACT_ADDRESS if currency.usdt?
      safely_parse(http_request(
        url: "#{API_URL}/transfer/#{endpoint}?#{params}",
        method: :GET,
        headers: build_headers
      ))['data']
    end

    private

    attr_reader :api_key, :currency

    def build_headers
      {
        'TRON-PRO-API-KEY' => api_key
      }
    end

    def endpoint
      CURRENCY_TO_ENDPOINT[currency] || raise("#{currency} is not supported")
    end
  end
end
