# frozen_string_literal: true

class PaymentServices::Tronscan
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://apilist.tronscanapi.com/api'
    USDT_TRC_CONTRACT_ADDRESS = 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t'
    CURRENCY_TO_ENDPOINT = {
      'trx'  => 'transaction',
      'usdt' => 'new/token_trc20/transfers'
    }.freeze

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @currency = currency.inquiry
    end

    def transactions(address:)
      if currency.usdt?
        params = { toAddress: address, contract_address: USDT_TRC_CONTRACT_ADDRESS }
      else
        params = { address: address, limit: 100 }
      end

      params = params.to_query
      response = safely_parse(http_request(
        url: "#{API_URL}/#{endpoint}?#{params}",
        method: :GET,
        headers: build_headers
      ))
      response['data'] || response['token_transfers']
    end

    private

    attr_reader :api_key, :currency

    def build_headers
      {
        # 'TRON-PRO-API-KEY' => api_key
      }
    end

    def endpoint
      CURRENCY_TO_ENDPOINT[currency] || raise("#{currency} is not supported")
    end
  end
end
