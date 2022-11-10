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
      'xrp'   => 'xrp'
    }.freeze
    TOKEN_NETWORK_TO_BLOCKCHAIN = {
      'trc20' => 'tron',
      'bep20' => 'binance-smart-chain',
      'erc20' => 'ethereum'
    }.freeze

    ACCOUNT_MODEL_BLOCKCHAINS  = %w(ethereum ethereum-classic binance-smart-chain xrp)
    FUNGIBLE_TOKENS = %w(usdt)
    delegate :xrp?, :bitcoin?, to: :blockchain

    def initialize(currency:, token_network:)
      @currency = currency
      @token_network = token_network
    end

    def address_transactions_endpoint(merchant_id:, address:)
      if blockchain.xrp?
        "#{blockchain_data_prefix}/xrp-specific/#{NETWORK}/addresses/#{address}/transactions"
      elsif fungible_token? || currency.inquiry.bnb?
        "#{proccess_payout_base_url(merchant_id)}/transactions"
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

    attr_reader :currency, :token_network

    def blockchain
      @blockchain ||= build_blockchain.inquiry
    end

    def build_blockchain
      currency.inquiry.usdt? ? TOKEN_NETWORK_TO_CURRENCY[token_network] : CURRENCY_TO_BLOCKCHAIN[currency]
    end

    def proccess_payout_base_url(merchant_id)
      "#{API_URL}/wallet-as-a-service/wallets/#{merchant_id}/#{blockchain}/#{NETWORK}"
    end

    def blockchain_data_prefix
      "#{API_URL}/blockchain-data"
    end
  end
end
