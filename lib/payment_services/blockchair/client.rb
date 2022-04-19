# frozen_string_literal: true

require_relative 'blockchain'

class PaymentServices::Blockchair
  class Client < ::PaymentServices::Base::Client
    def initialize(api_key:, currency:)
      @api_key  = api_key
      @blockchain = Blockchain.new(currency: currency)
    end

    def transaction_ids(address:)
      safely_parse http_request(
        url: "#{blockchain.transaction_ids_endpoint(address)}#{api_suffix}",
        method: :GET,
        headers: build_headers
      )
    end

    def transactions_data(tx_ids:)
      safely_parse http_request(
        url: "#{blockchain.transactions_data_endpoint(tx_ids)}#{api_suffix}",
        method: :GET,
        headers: build_headers
      )
    end

    def stellar_transactions(address:)
      safely_parse http_request(
        url: "https://api.blockchair.com/stellar/raw/account/#{address}?transactions=true&account=false",
        method: :GET,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :blockchain

    def api_suffix
      api_key ? "?key=#{api_key}" : ''
    end

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Cache-Control' => 'no-cache'
      }
    end
  end
end
