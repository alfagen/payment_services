# frozen_string_literal: true

require_relative '../clients/base_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class BaseClient < PaymentServices::CryptoApis::Clients::BaseClient
      DEFAULT_PARAMS = { replaceable: true }

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

      def amount_with_fee_of(payout:)
        @amount_with_fee_of ||= payout.amount.to_d + payout.fee
      end

      def api_query_for(payout, wallet)
        {
          createTx: {
            inputs: [{ address: wallet.account, value: amount_with_fee_of(payout: payout) }],
            outputs: [{ address: payout.address, value: amount_with_fee_of(payout: payout) }],
            fee: {
              value: payout.fee
            }
          },
          wifs: [ wallet.api_secret ]
        }.merge(DEFAULT_PARAMS)
      end
    end
  end
end
