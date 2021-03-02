# frozen_string_literal: true

require_relative '../clients/ethereum_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class PayoutEthereumClient < PaymentServices::CryptoApis::Clients::EthereumClient
      STANDART_GAS_LIMIT = 21000

      def make_payout(payout:, wallet:)
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
          gasLimit: STANDART_GAS_LIMIT,
          gasPrice: payout.fee,
          value: payout.amount.to_d,
          privateKey: wallet.api_secret
        }
      end
    end
  end
end
