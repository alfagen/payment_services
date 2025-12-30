# frozen_string_literal: true

require_relative 'base_client'

module PaymentServices
  class CryptoApis
    module PayoutClients
      class DashClient < PaymentServices::CryptoApis::PayoutClients::BaseClient
        DEPRECATED_OPTION = { deprecated_rpc: 'sign_raw_transaction' }

        def make_payout(payout:, wallet_transfers:)
          safely_parse http_request(
            url: "#{base_url}/txs/new",
            method: :POST,
            body: api_query_for(payout, wallet_transfers).merge(DEPRECATED_OPTION)
          )
        end

        private

        def base_url
          "#{API_URL}/bc/dash/#{NETWORK}"
        end
      end
    end
  end
end
