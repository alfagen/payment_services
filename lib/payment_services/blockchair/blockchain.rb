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
      xmr:  'monero',
      ada:  'cardano'
    }.freeze

    def initialize(currency:)
      @currency = currency
    end

    def transaction_ids_endpoint(address)
      if blockchain.monero?
        "#{API_URL}/#{blockchain}/raw/outputs?address=#{address}"
      elsif blockchain.cardano?
        "#{API_URL}/#{blockchain}/raw/address/#{address}"
      else
        "#{API_URL}/#{blockchain}/dashboards/address/#{address}"
      end
    end

    def transactions_data_endpoint(tx_ids)
      if blockchain.monero?
        "#{API_URL}/#{blockchain}/dashboards/raw/transactions/#{tx_ids.first}"
      else
        "#{API_URL}/#{blockchain}/dashboards/transactions/#{tx_ids.join(',')}"
      end
    end

    def blockchain
      @blockchain ||= CURRENCY_TO_BLOCKCHAIN[currency.to_sym].inquiry
    end

    private

    attr_reader :currency
  end
end
