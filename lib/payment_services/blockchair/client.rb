# frozen_string_literal: true

class PaymentServices::Blockchair
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://api.blockchair.com'
    CURRENCY_TO_BLOCKCHAIN = {
      'btc'   => 'bitcoin',
      'bch'   => 'bitcoin-cash',
      'ltc'   => 'litecoin',
      'doge'  => 'dogecoin',
      'dsh'   => 'dash',
      'zec'   => 'zcash'
    }

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @currency = currency
    end

    def transaction_ids(address:)
      safely_parse http_request(
        url: "#{API_URL}/#{blockchain}/dashboards/address/#{address}#{api_suffix}",
        method: :GET,
        headers: build_headers
      )
    end

    def transactions_information(tx_ids:)
      safely_parse http_request(
        url: "#{API_URL}/#{blockchain}/dashboards/transactions/#{tx_ids.join(',')}#{api_suffix}",
        method: :GET,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :currency

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency]
    end

    def api_suffix
      return "?key=#{api_key}" if api_key

      ''
    end

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Cache-Control' => 'no-cache'
      }
    end
  end
end
