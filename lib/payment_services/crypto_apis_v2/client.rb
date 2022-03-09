# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Client < ::PaymentServices::Base::Client
    include AutoLogger

    TIMEOUT = 30
    API_URL = 'https://rest.cryptoapis.io/v2'
    NETWORK = 'mainnet'
    CURRENCY_TO_BLOCKCHAIN = {
      'btc'   => 'bitcoin',
      'bch'   => 'bitcoin-cash',
      'ltc'   => 'litecoin',
      'doge'  => 'dogecoin',
      'dsh'   => 'dash',
      'eth'   => 'ethereum',
      'etc'   => 'ethereum-classic',
      'bnb'   => 'binance-smart-chain',
      'zec'   => 'zcash'
    }

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @currency = currency
    end

    def address_transactions(address)
      safely_parse http_request(
        url: "#{base_url}/addresses/#{address}/transactions",
        method: :GET
      )
    end

    def transaction_details(transaction_id)
      safely_parse http_request(
        url: "#{base_url}/transactions/#{transaction_id}",
        method: :GET
      )
    end

    private

    attr_reader :api_key, :currency

    def base_url
      "#{API_URL}/blockchain-data/#{blockchain}/#{NETWORK}"
    end

    def headers
      {
        'Content-Type'  : 'application/json',
        'Cache-Control' : 'no-cache',
        'X-API-Key'     : api_key
      }
    end

    def blockchain
      CURRENCY_TO_BLOCKCHAIN[currency]
    end
  end
end
