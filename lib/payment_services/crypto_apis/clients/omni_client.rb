# frozen_string_literal: true

require_relative 'client'

class PaymentServices::CryptoApis
  class OmniClient < PaymentServices::CryptoApis::Client
    def address_transactions(address)
      safely_parse http_request(
        url: "#{base_url}/",
        method: :GET
      )
    end

    def transaction_details(transaction_id)
      safely_parse http_request(
        url: "#{base_url}/",
        method: :GET
      )
    end

    private

    def base_url
      "#{API_URL}/bc/btc/#{currency}/#{NETWORK}"
    end
  end
end
