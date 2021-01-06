# frozen_string_literal: true

require_relative 'payout_client'
require_relative 'wallet'
require_relative 'payout_payment'
require_relative 'payout'

class PaymentServices::CryptoApis
  class PayoutAdapter
    # payout_wallets - хеш из кошельков(кошелька) для снятия средств с уже просчитанными суммами в формате:
    # { wallet_id => payout_amount }
    def initialize(order:, payout_wallets:)
      @order = order
      @payout_wallets = payout_wallets
    end

    attr_reader :order, :payout_wallets

    def create_payout(amount, destination_address, fee)
      payout = Payout.new(amount: amount, order_public_id: order.public_id, destination_address: destination_address, fee: fee)

      payout_wallets.each do |wallet_id, payout_amount|
        payout.payout_payments.new(wallet_id: wallet_id, amount: payout_amount)
      end

      payout.save!
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
      payout.payout_payments.inject([]) do |memo, payment|
        memo << { address: payment.wallet.address, value: payment.amount }
      end
    end

    def outputs
      [{ address: payout.destination_address, value: payout.amount }]
    end

    def wifs
      payout.wallets.inject([]) do |memo, wallet| 
        memo << wallet.wif
      end
    end
  end
end
