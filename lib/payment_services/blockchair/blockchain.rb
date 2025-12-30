# frozen_string_literal: true

module PaymentServices
  class Blockchair
    class Blockchain
      API_URL = 'https://api.blockchair.com'
      CURRENCY_TO_BLOCKCHAIN = {
        btc:  'bitcoin',
        bch:  'bitcoin_cash',
        ltc:  'litecoin',
        doge: 'dogecoin',
        dsh:  'dash',
        zec:  'zcash',
        eth:  'ethereum',
        ada:  'cardano',
        xlm:  'stellar',
        xrp:  'ripple',
        eos:  'eos',
        usdt: 'erc_20'
      }.freeze
      USDT_ERC_CONTRACT_ADDRESS = '0xdac17f958d2ee523a2206206994597c13d831ec7'
      BLOCKCHAIN_TO_AMOUNT_DIVIDER = {
        'ethereum'  => 1e+18,
        'cardano'   => 1e+6,
        'ripple'    => 1e+6,
        'erc_20'    => 1e+6,
      }.freeze
      DEFAULT_AMOUNT_DIVIDER = 1e+8

      delegate :ethereum?, :cardano?, :stellar?, :ripple?, :eos?, :erc_20?, to: :blockchain

      def initialize(currency:)
        @currency = currency
      end

      def name
        blockchain
      end

      def transactions_endpoint(address)
        if cardano?
          "#{blockchain_base_api}/raw/address/#{address}"
        elsif stellar?
          "#{raw_account_base_url(address)}?payments=true&account=false"
        elsif ripple?
          "#{raw_account_base_url(address)}?transactions=true"
        elsif eos?
          "#{raw_account_base_url(address)}?actions=true"
        elsif erc_20?
          "#{API_URL}/ethereum/erc-20/#{USDT_ERC_CONTRACT_ADDRESS}/dashboards/address/#{address}"
        else
          "#{blockchain_base_api}/dashboards/address/#{address}"
        end
      end

      def transactions_data_endpoint(tx_ids)
        "#{blockchain_base_api}/dashboards/transactions/#{tx_ids.join(',')}"
      end

      def amount_divider
        BLOCKCHAIN_TO_AMOUNT_DIVIDER[blockchain] || DEFAULT_AMOUNT_DIVIDER 
      end

      private

      attr_reader :currency

      def blockchain
        @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency.to_sym].inquiry
      end

      def blockchain_base_api
        "#{API_URL}/#{blockchain_url}"
      end

      def raw_account_base_url(address)
        "#{blockchain_base_api}/raw/account/#{address}"
      end
    
      def blockchain_url
        blockchain.bitcoin_cash? ? 'bitcoin-cash' : blockchain
      end
    end
  end
end
