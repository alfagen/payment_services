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
        inputs = []
        wifs = []

        raise wallets.to_s

        if wallets
          wallets.each do |current_wallet, amount| 
            inputs.push({ address: current_wallet.account, value: amount })
            wifs.push(current_wallet.api_secret)
          end
        else
          inputs.push({ address: wallet.account, value: payout.amount.to_d })
          wifs.push(wallet.api_secret)
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
