# frozen_string_literal: true

require_relative '../clients/omni_client'

class PaymentServices::CryptoApis
  class PayoutOmniClient < PaymentServices::CryptoApis::OmniClient
    def make_payout(payout:, wallet:)
      safely_parse http_request(
        url: "#{base_url}/",
        method: :POST,
        body: api_query_for(payout, wallet)
      )
    end

    def transaction_details(txid)
      safely_parse http_request(
        url: "#{base_url}/",
        method: :GET
      )
    end

    def transactions_average_fee
      safely_parse(http_request(
        url: "#{base_url}/",
        method: :GET
      ))
    end

    private

    def api_query_for(payout, wallet)
      {
        
      }
    end
  end
end
