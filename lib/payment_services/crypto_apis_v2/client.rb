# frozen_string_literal: true

require_relative 'blockchain'

class PaymentServices::CryptoApisV2
  class Client < ::PaymentServices::Base::Client
    include AutoLogger

    DEFAULT_FEE_PRIORITY  = 'standard'
    LOW_FEE_PRIORITY      = 'slow'

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
        body: build_payout_request_body(payout: payout, wallet_transfer: wallet_transfer).to_json,
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

    def build_payout_request_body(payout:, wallet_transfer:)
      transaction_body = 
        if blockchain.fungible_token?
          build_fungible_payout_body(payout, wallet_transfer)
        elsif blockchain.account_model_blockchain?
          build_account_payout_body(payout, wallet_transfer)
        else
          build_utxo_payout_body(payout, wallet_transfer)
        end

      { data: { item: transaction_body } }
    end

    def build_account_payout_body(payout, wallet_transfer)
      {
        amount: wallet_transfer.amount.to_f.to_s,
        feePriority: account_fee_priority,
        callbackSecretKey: wallet_transfer.wallet.api_secret,
        recipientAddress: payout.address
      }
    end

    def build_utxo_payout_body(payout, wallet_transfer)
      {
        callbackSecretKey: wallet_transfer.wallet.api_secret,
        feePriority: utxo_fee_priority,
        recipients: [{
          address: payout.address,
          amount: wallet_transfer.amount.to_f.to_s
        }]
      }
    end

    def build_fungible_payout_body(payout, wallet_transfer)
      token_network = wallet_transfer.wallet.payment_system.token_network.downcase
      build_account_payout_body(payout, wallet_transfer).merge(tokenIdentifier: token_network)
    end

    def account_fee_priority
      blockchain.fungible_token? ? LOW_FEE_PRIORITY : DEFAULT_FEE_PRIORITY
    end

    def utxo_fee_priority
      blockchain.zcash_blockchain? ? LOW_FEE_PRIORITY : DEFAULT_FEE_PRIORITY
    end
  end
end
