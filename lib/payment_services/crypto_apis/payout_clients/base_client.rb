# frozen_string_literal: true

require_relative '../clients/base_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class BaseClient < PaymentServices::CryptoApis::Clients::BaseClient
      DEFAULT_PARAMS = { replaceable: true }

      def make_payout(payout:, wallet_transfers:)
        safely_parse http_request(
          url: "#{base_url}/txs/new",
          method: :POST,
          body: api_query_for(payout, wallet_transfers)
        )
      end

      def transactions_average_fee
        safely_parse(http_request(
          url: "#{base_url}/txs/fee",
          method: :GET
        ))
      end

      private

      def api_query_for(payout, wallet_transfers)
        {
          createTx: {
            inputs: inputs(wallet_transfers),
            outputs: [{ address: payout.address, value: payout.amount.to_d }],
            fee: { value: payout.fee }.merge(payout.pay_fee_from_address)
          },
          wifs: wifs(wallet_transfers)
        }.merge(DEFAULT_PARAMS)
      end

      def inputs(wallet_transfers)
        wallet_transfers.map { |wallet_transfer| { 'address' => wallet_transfer.wallet.account, 'value' => wallet_transfer.amount.to_f } }
      end

      def wifs(wallet_transfers)
        wallet_transfers.map { |wallet_transfer| wallet_transfer.wallet.api_secret }
      end
    end
  end
end
