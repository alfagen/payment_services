# frozen_string_literal: true

require_relative 'blockchain'

class PaymentServices::CryptoApisV2
  class Client < ::PaymentServices::Base::Client
    include AutoLogger

    API_URL = 'https://rest.cryptoapis.io/v2'
    NETWORK = 'mainnet'
    DEFAULT_FEE_PRIORITY = 'standard'

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @blockchain = Blockchain.new(currency: currency)
    end

    def address_transactions(address)
      safely_parse http_request(
        url: blockchain.address_transactions_endpoint(address),
        method: :GET,
        headers: build_headers
      )
    end

    def transaction_details(transaction_id)
      safely_parse http_request(
        url: blockchain.transaction_details_endpoint(transaction_id),
        method: :GET,
        headers: build_headers
      )
    end

    def request_details(request_id)
      safely_parse http_request(
        url: blockchain.request_details_endpoint(request_id),
        method: :GET,
        headers: build_headers
      )
    end

    def make_payout(payout:, wallet_transfers:)
      wallet_transfer = wallet_transfers.first

      safely_parse http_request(
        url: blockchain.process_payout_endpoint(wallet: wallet_transfer.wallet),
        method: :POST,
        body: blockchain.build_payout_request_body(payout: payout, wallet_transfer: wallet_transfer).to_json,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :blockchain

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Cache-Control' => 'no-cache',
        'X-API-Key'     => api_key
      }
    end
  end
end
