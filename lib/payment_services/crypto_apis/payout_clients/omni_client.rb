# frozen_string_literal: true

require_relative '../clients/omni_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class OmniClient < PaymentServices::CryptoApis::Clients::OmniClient
      TOKEN_PROPERTY_ID = 2

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
          from: wallet.account,
          to: payout.address,
          value: amount_with_fee_of(payout: payout),
          fee: payout.fee,
          propertyID: TOKEN_PROPERTY_ID,
          wif: wallet.api_secret
        }
      end
    end
  end
end
