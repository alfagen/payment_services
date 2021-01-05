# frozen_string_literal: true

require_relative 'payout'
require_relative 'payout_client'

class PaymentServices::CryptoApis
  class PayoutAdapter
    # payout_wallets - массив из адресов кошельков(кошелька) с уже просчитанными суммами в формате:
    # [{ address: 'fh4..', payout_amount: 0.004, wif: 'fhf..' }..]
    def initialize(order:, payout_wallets:)
      @order, @payout_wallets = order, payout_wallets
    end

    attr_reader :order, :payout_wallets

    def create_payout(amount_cents, destination_address, fee)
      Payout.create!(amount_cents: amount_cents, order_public_id: order.public_id, destination_address: destination_address, fee: fee)
    end

    def make_payout!
      response = client.make_payout(query: api_query)
      raise "Can't process payout: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.pay!(txid: response[:payload][:txid])
    end

    def refresh_status!
      return if payout.pending?

      transaction = client.transaction_details(txid: payout.txid)[:payload]
      payout.update!(confirmation: transaction[:confirmations])

      payout.confirmed! if payout.complete_payment?
    end

    def payout
      @payout ||= Payout.find_by(order_public_id: order.public_id)
    end

    private

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        PayoutClient.new(wallet.api_key)
      end
    end

    def api_query
      {
        createTx: {
          inputs: inputs,
          outputs: outputs,
          fee: {
            value: payout.fee
          }
        },
        wifs: wifs
      }
    end

    def inputs
      payout_wallets.inject([]) do |memo, wallet|
        memo << { address: wallet[:address], value: wallet[:payout_amount] }
      end
    end

    def outputs
      [{ address: payout.destination_address, value: payout.amount_cents }]
    end

    def wifs
      payout_wallets.inject([]) do |memo, wallet| 
        memo << wallet[:wif]
      end
    end
  end
end
