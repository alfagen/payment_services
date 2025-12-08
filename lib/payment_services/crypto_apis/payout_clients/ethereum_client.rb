# frozen_string_literal: true

require_relative '../clients/ethereum_client'

module PaymentServices
  class CryptoApis
    module PayoutClients
      class EthereumClient < PaymentServices::CryptoApis::Clients::EthereumClient
        GAS_LIMIT = 100_000

        def make_payout(payout:, wallet_transfers:)
          safely_parse http_request(
            url: "#{base_url}/txs/new-pvtkey",
            method: :POST,
            body: api_query_for(payout, wallet_transfers.first.wallet)
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
            gasPrice: payout.fee.to_i,
            gasLimit: GAS_LIMIT,
            privateKey: wallet.outcome_api_secret
          }
        end
      end
    end
  end
end
