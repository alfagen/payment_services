# frozen_string_literal: true

require_relative '../clients/base_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class BaseClient < PaymentServices::CryptoApis::Clients::BaseClient
      def make_payout(payout:, wallet:)
        safely_parse http_request(
          url: "#{base_url}/txs/new",
          method: :POST,
          body: api_query_for(payout, wallet)
        )
      end

      def transactions_average_fee
        safely_parse(http_request(
          url: "#{base_url}/txs/fee",
          method: :GET
        ))
      end

      private

      def api_query_for(payout, wallet)
        {
          createTx: {
            inputs: [{ address: wallet.account, value: payout.amount.to_d }],
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
end
