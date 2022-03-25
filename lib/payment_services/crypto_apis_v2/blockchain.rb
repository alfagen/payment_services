# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Blockchain
    API_URL = 'https://rest.cryptoapis.io/v2'
    NETWORK = 'mainnet'
    DEFAULT_FEE_PRIORITY = 'standard'
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
    ACCOUNT_MODEL_BLOCKCHAINS  = %w(ethereum ethereum-classic binance-smart-chain xrp)
    FUNGIBLE_TOKENS = %w(usdt)

    def initialize(currency:)
      @currency = currency
    end

    def address_transactions_endpoint(address)
      unless xrp_blockchain?
        "#{API_URL}/blockchain-data/#{blockchain}/#{NETWORK}/addresses/#{address}/transactions"
      else
        "#{API_URL}/blockchain-data/xrp-specific/#{NETWORK}/addresses/#{address}/transactions"
      end
    end

    def transaction_details_endpoint(transaction_id)
      unless xrp_blockchain?
        "#{API_URL}/wallet-as-a-service/wallets/#{blockchain}/#{NETWORK}/transactions/#{transaction_id}"
      else
        "#{API_URL}/blockchain-data/xrp-specific/#{NETWORK}/transactions/#{transaction_id}"
      end  
    end

    def request_details_endpoint(request_id)
      "#{API_URL}/wallet-as-a-service/transactionRequests/#{request_id}"
    end

    def process_payout_endpoint(wallet:)
      if fungible_tokens?
        "#{proccess_payout_base_url(wallet.merchant_id)}/addresses/#{wallet.account}/token-transaction-requests"
      elsif account_model_blockchain?
        "#{proccess_payout_base_url(wallet.merchant_id)}/addresses/#{wallet.account}/transaction-requests"
      else
        "#{proccess_payout_base_url(wallet.merchant_id)}/transaction-requests"
      end
    end

    def build_payout_request_body(payout:, wallet_transfer:)
      transaction_body = 
        if fungible_tokens?
          build_fungible_payout_body(payout, wallet_transfer)
        elsif account_model_blockchain?
          build_account_payout_body(payout, wallet_transfer)
        else
          build_utxo_payout_body(payout, wallet_transfer)
        end

      { data: { item: transaction_body } }
    end

    private

    attr_reader :currency

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency]
    end

    def xrp_blockchain?
      blockchain == 'xrp'
    end

    def fungible_tokens?
      FUNGIBLE_TOKENS.include?(currency)
    end

    def account_model_blockchain?
      ACCOUNT_MODEL_BLOCKCHAINS.include?(blockchain)
    end

    def proccess_payout_base_url(merchant_id)
      "#{API_URL}/wallet-as-a-service/wallets/#{merchant_id}/#{blockchain}/#{NETWORK}"
    end

    def build_account_payout_body(payout, wallet_transfer)
      {
        amount: wallet_transfer.amount.to_f.to_s,
        feePriority: DEFAULT_FEE_PRIORITY,
        callbackSecretKey: wallet_transfer.wallet.api_secret,
        recipientAddress: payout.address
      }
    end

    def build_utxo_payout_body(payout, wallet_transfer)
      {
        callbackSecretKey: wallet_transfer.wallet.api_secret,
        feePriority: DEFAULT_FEE_PRIORITY,
        recipients: [{
          address: payout.address,
          amount: wallet_transfer.amount.to_f.to_s
        }]
      }
    end

    def build_fungible_payout_body(payout, wallet_transfer)
      token_network = wallet_transfer.wallet.payment_system.token_network
      build_account_payout_body(payout, wallet_transfer).merge(tokenIdentifier: token_network)
    end
  end
end
