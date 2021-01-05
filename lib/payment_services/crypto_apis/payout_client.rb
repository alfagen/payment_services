# frozen_string_literal: true

require_relative 'client'

class PaymentServices::CryptoApis
  class PayoutClient < PaymentServices::CryptoApis::Client
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
