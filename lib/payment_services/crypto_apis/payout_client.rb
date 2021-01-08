# frozen_string_literal: true

require_relative 'client'

class PaymentServices::CryptoApis
  class PayoutClient < PaymentServices::CryptoApis::Client
    def make_payout(query:)
      safely_parse http_request(
        url: "#{API_URL}/bc/#{currency}/#{NETWORK}/txs/new",
        method: :POST,
        body: query
      )
    end

    def transaction_details(txid)
      safely_parse http_request(
        url: "#{API_URL}/bc/#{currency}/#{NETWORK}/txs/txid/#{txid}",
        method: :GET
      )
    end
  end
end
