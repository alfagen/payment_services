# frozen_string_literal: true

require_relative 'client'

class PaymentServices::CryptoApis
  class EthereumClient < PaymentServices::CryptoApis::Client
    def transaction_details(transaction_id)
      safely_parse http_request(
        url: "#{base_url}/txs/basic/hash/#{transaction_id}",
        method: :GET
      )
    end

    private

    def network
      return 'mainnet' if Rails.env.production?

      currency == 'eth' ? 'rinkeby' : 'mordor'
    end

    def base_url
      "#{API_URL}/bc/#{currency}/#{network}"
    end
  end
end
