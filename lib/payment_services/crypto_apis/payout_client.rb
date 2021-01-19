# frozen_string_literal: true

require_relative 'client'

class PaymentServices::CryptoApis
  class PayoutClient < PaymentServices::CryptoApis::Client
    def make_payout(payout:, wallet:)
      safely_parse http_request(
        url: "#{base_url}/txs/new",
        method: :POST,
        body: api_query_for(payout, wallet)
      )
    end

    def transaction_details(txid)
      safely_parse http_request(
        url: "#{base_url}/txs/txid/#{txid}",
        method: :GET
      )
    end

    def transactions_average_fee
      safely_parse(http_request(
        url: "#{base_url}/txs/fee",
        method: :GET
      ))[:payload][:average]
    end

    private

    def api_query_for(payout, wallet)
      {
        createTx: {
          inputs: [{ address: wallet.address, value: payout.amount.to_d }],
          outputs: [{ address: payout.address, value: payout.amount.to_d }],
          fee: {
            value: payout.fee
          }
        },
        wifs: [ wallet.api_secret ]
      }
    end
  end
end
