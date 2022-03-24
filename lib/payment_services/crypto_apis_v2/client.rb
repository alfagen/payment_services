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
      'zec'   => 'zcash',
      'xrp'   => 'xrp'
    }
    DEFAULT_FEE_PRIORITY = 'standard'
    ADDRESS_BLOCKCHAINS  = %w(ethereum ethereum-classic binance-smart-chain xrp)

    def initialize(api_key:, currency:)
      @api_key  = api_key
      @currency = currency
    end

    def address_transactions(address)
      safely_parse http_request(
        url: address_transactions_endpoint(address),
        method: :GET,
        headers: build_headers
      )
    end

    def transaction_details(transaction_id)
      safely_parse http_request(
        url: transaction_details_endpoint(transaction_id),
        method: :GET,
        headers: build_headers
      )
    end

    def request_details(request_id)
      safely_parse http_request(
        url: "#{API_URL}/wallet-as-a-service/transactionRequests/#{request_id}",
        method: :GET,
        headers: build_headers
      )
    end

    def make_payout(payout:, wallet_transfers:)
      wallet_transfer = wallet_transfers.first

      safely_parse http_request(
        url: payout_endpoint(wallet_transfer.wallet),
        method: :POST,
        body: build_body(wallet_transfer, payout).to_json,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :currency

    def build_headers
      {
        'Content-Type'  => 'application/json',
        'Cache-Control' => 'no-cache',
        'X-API-Key'     => api_key
      }
    end

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency]
    end

    def payout_endpoint(wallet)
      if ADDRESS_BLOCKCHAINS.include?(blockchain)
        "#{API_URL}/wallet-as-a-service/wallets/#{wallet.merchant_id}/#{blockchain}/#{NETWORK}/addresses/#{wallet.account}/transaction-requests"
      else
        "#{API_URL}/wallet-as-a-service/wallets/#{wallet.merchant_id}/#{blockchain}/#{NETWORK}/transaction-requests"
      end
    end

    def build_body(wallet_transfer, payout)
      item =  if ADDRESS_BLOCKCHAINS.include?(blockchain)
                build_address_body(payout, wallet_transfer)
              else
                build_utxo_body(payout, wallet_transfer)
              end
      {
        data: {
          item: item
        }
      }
    end

    def build_address_body(payout, wallet_transfer)
      {
        amount: wallet_transfer.amount.to_f.to_s,
        feePriority: DEFAULT_FEE_PRIORITY,
        callbackSecretKey: wallet_transfer.wallet.api_secret,
        recipientAddress: payout.address
      }
    end

    def build_utxo_body(payout, wallet_transfer)
      {
        callbackSecretKey: wallet_transfer.wallet.api_secret,
        feePriority: DEFAULT_FEE_PRIORITY,
        recipients: [{
          address: payout.address,
          amount: wallet_transfer.amount.to_f.to_s
        }]
      }
    end

    def address_transactions_endpoint(address)
      unless blockchain == 'xrp'
        "#{API_URL}/blockchain-data/#{blockchain}/#{NETWORK}/addresses/#{address}/transactions"
      else
        "#{API_URL}/blockchain-data/xrp-specific/#{NETWORK}/addresses/#{address}/transactions"
      end
    end

    def transaction_details_endpoint(transaction_id)
      unless blockchain == 'xrp'
        "#{API_URL}/wallet-as-a-service/wallets/#{blockchain}/#{NETWORK}/transactions/#{transaction_id}"
      else
        "#{API_URL}/blockchain-data/xrp-specific/#{NETWORK}/transactions/#{transaction_id}"
      end  
    end
  end
end
