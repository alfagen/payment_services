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

    def transactions_endpoint(address)
      if cardano?
        "#{API_URL}/#{blockchain}/raw/address/#{address}"
      elsif stellar?
        "#{API_URL}/#{blockchain}/raw/account/#{address}?payments=true&account=false"
      else
        "#{API_URL}/#{blockchain}/dashboards/address/#{address}"
      end
    end

    def transactions_data_endpoint(tx_ids)
      "#{API_URL}/#{blockchain}/dashboards/transactions/#{tx_ids.join(',')}"
    end

    private

    attr_reader :currency

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency.to_sym].inquiry
    end
  end
end
