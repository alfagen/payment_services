# frozen_string_literal: true

class PaymentServices::Blockchair
  class Blockchain
    API_URL = 'https://api.blockchair.com'
    CURRENCY_TO_BLOCKCHAIN = {
      btc:  'bitcoin',
      bch:  'bitcoin-cash',
      ltc:  'litecoin',
      doge: 'dogecoin',
      dsh:  'dash',
      zec:  'zcash',
      eth:  'ethereum',
      ada:  'cardano',
      xlm:  'stellar'
    }.freeze

    delegate :ethereum?, :cardano?, :stellar?, to: :blockchain

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
        "#{blockchain_base_api}/raw/account/#{address}?payments=true&account=false"
      else
        "#{blockchain_base_api}/dashboards/address/#{address}"
      end
    end

    def transactions_data_endpoint(tx_ids)
      "#{blockchain_base_api}/dashboards/transactions/#{tx_ids.join(',')}"
    end

    private

    attr_reader :currency

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency.to_sym].inquiry
    end

    def blockchain_base_api
      "#{API_URL}/#{blockchain}"
    end
  end
end
