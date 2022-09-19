# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Blockchain
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
      'xrp'   => 'xrp',
      'usdt'  => 'tron'
    }
    ACCOUNT_MODEL_BLOCKCHAINS  = %w(ethereum ethereum-classic binance-smart-chain xrp)
    FUNGIBLE_TOKENS = %w(usdt)
    delegate :xrp?, :bitcoin?, to: :blockchain

    def initialize(currency:)
      @currency = currency
    end

    def address_transactions_endpoint(address)
      if blockchain.xrp?
        "#{blockchain_data_prefix}/xrp-specific/#{NETWORK}/addresses/#{address}/transactions"
      elsif fungible_token?
        "#{blockchain_data_prefix}/#{blockchain}/#{NETWORK}/addresses/#{address}/tokens-transfers"
      else
        "#{blockchain_data_prefix}/#{blockchain}/#{NETWORK}/addresses/#{address}/transactions"
      end
    end

    def transaction_details_endpoint(transaction_id)
      if blockchain.xrp?
        "#{blockchain_data_prefix}/xrp-specific/#{NETWORK}/transactions/#{transaction_id}"
      else
        "#{API_URL}/wallet-as-a-service/wallets/#{blockchain}/#{NETWORK}/transactions/#{transaction_id}"
      end  
    end

    def request_details_endpoint(request_id)
      "#{API_URL}/wallet-as-a-service/transactionRequests/#{request_id}"
    end

    def process_payout_endpoint(wallet:)
      if fungible_token?
        "#{proccess_payout_base_url(wallet.merchant_id)}/addresses/#{wallet.account}/feeless-token-transaction-requests"
      elsif account_model_blockchain?
        "#{proccess_payout_base_url(wallet.merchant_id)}/addresses/#{wallet.account}/transaction-requests"
      else
        "#{proccess_payout_base_url(wallet.merchant_id)}/transaction-requests"
      end
    end

    def fungible_token?
      FUNGIBLE_TOKENS.include?(currency)
    end

    def account_model_blockchain?
      ACCOUNT_MODEL_BLOCKCHAINS.include?(blockchain)
    end

    private

    attr_reader :currency

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency].inquiry
    end

    def proccess_payout_base_url(merchant_id)
      "#{API_URL}/wallet-as-a-service/wallets/#{merchant_id}/#{blockchain}/#{NETWORK}"
    end

    def blockchain_data_prefix
      "#{API_URL}/blockchain-data"
    end
  end
end
