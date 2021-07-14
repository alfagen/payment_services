# frozen_string_literal: true

require_relative '../clients/ethereum_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class EthereumClient < PaymentServices::CryptoApis::Clients::EthereumClient
      def make_payout(payout:, wallet:, wallets: nil)
        safely_parse http_request(
          url: "#{base_url}/txs/new-pvtkey",
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
          fromAddress: wallet.account,
          toAddress: payout.address,
          value: payout.amount.to_d,
          privateKey: wallet.api_secret
        }
      end
    end
  end
end
