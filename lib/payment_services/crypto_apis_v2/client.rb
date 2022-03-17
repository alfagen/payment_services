# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Client < ::PaymentServices::Base::Client
    include AutoLogger

    TIMEOUT = 30
    API_URL = 'https://rest.cryptoapis.io/v2'
    NETWORK = 'testnet'
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
    DEFAULT_FEE_PRIORITY = 'standard'

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @currency = currency
    end

    def address_transactions(address)
      safely_parse http_request(
        url: "#{base_url}/addresses/#{address}/transactions",
        method: :GET,
        headers: build_headers
      )
    end

    def transaction_details(transaction_id)
      safely_parse http_request(
        url: "#{API_URL}/wallet-as-a-service/wallets/#{blockchain}/#{NETWORK}/transactions/#{transaction_id}",
        method: :GET,
        headers: build_headers
      )
    end

    def get_transaction_id(request_id)
      safely_parse http_request(
        url: "#{API_URL}/wallet-as-a-service/transactionRequests/#{request_id}",
        method: :GET,
        headers: build_headers
      )
    end

    def make_payout(payout:, wallet_transfers:)
      wallet_transfers.each do |wallet_transfer|
        body = {
          data: {
            item: {
              callbackSecretKey: wallet_transfer.wallet.api_secret,
              feePriority: DEFAULT_FEE_PRIORITY,
              recipients: [{
                address: payout.address,
                wallet_transfer.amount.to_f.to_s
              }]
            }
          }
        }
        safely_parse http_request(
          url: "#{API_URL}/wallet-as-a-service/wallets/#{wallet_transfer.wallet.merchant_id}/#{blockchain}/#{NETWORK}/transaction-requests",
          method: :POST,
          body: body,
          headers: build_headers
        )
      end
    end

    private

    attr_reader :api_key, :currency

    def base_url
      "#{API_URL}/blockchain-data/#{blockchain}/#{NETWORK}"
    end

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Cache-Control' => 'no-cache',
        'X-API-Key'     => api_key
      }
    end

    def blockchain
      CURRENCY_TO_BLOCKCHAIN[currency]
    end
  end
end
