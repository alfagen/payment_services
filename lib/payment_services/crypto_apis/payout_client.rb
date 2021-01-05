# frozen_string_literal: true

require_relative 'client'

class PaymentServices::CryptoApis
  class PayoutClient < PaymentServices::CryptoApis::Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://api.cryptoapis.io/v1'
    NETWORK = 'testnet'

    def initialize(api_key)
      @api_key = api_key
    end

    attr_reader :api_key

    def make_payout(inputs:, outputs:, fee:, wifs:)
      safely_parse http_request(
        url: "#{API_URL}/bc/bch/#{NETWORK}/txs/new",
        method: :POST,
        body: {
          createTx: {
            inputs: inputs,
            outputs: outputs,
            fee: {
              value: fee
            }
          },
          wifs: wifs
        }
      )
    end

    def info(txid)
      safely_parse http_request(
        url: "#{API_URL}/bc/bch/#{NETWORK}/txs/txid/#{txid}",
        method: :GET
      )
    end
  end
end
