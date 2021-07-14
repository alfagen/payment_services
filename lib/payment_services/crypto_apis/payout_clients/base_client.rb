# frozen_string_literal: true

require_relative '../clients/base_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class BaseClient < PaymentServices::CryptoApis::Clients::BaseClient
      DEFAULT_PARAMS = { replaceable: true }

      def make_payout(payout:, wallet:, wallets:)
        safely_parse http_request(
          url: "#{base_url}/txs/new",
          method: :POST,
          body: api_query_for(payout, wallet, wallets)
        )
      end

      def transactions_average_fee
        safely_parse(http_request(
          url: "#{base_url}/txs/fee",
          method: :GET
        ))
      end

      private

      def api_query_for(payout, wallet, wallets)
        if wallets
          inputs = wallets.map { |wallet, amount| { address: wallet.account, value: amount } }
          wifs = wallets.map { |wallet, amount| wallet.api_secret }
        else
          inputs = [{ address: wallet.account, value: payout.amount.to_d }]
          wifs = [ wallet.api_secret ]
        end

        {
          createTx: {
            inputs: inputs,
            outputs: [{ address: payout.address, value: payout.amount.to_d }],
            fee: {
              value: payout.fee
            }
          },
          wifs: wifs
        }.merge(DEFAULT_PARAMS)
      end
    end
  end
end
