# frozen_string_literal: true

require_relative 'payout_client'
require_relative 'wallet'
require_relative 'payout_payment'
require_relative 'payout'

class PaymentServices::CryptoApis
  class PayoutAdapter
    # payout_wallets - хеш из кошельков(кошелька) для снятия средств
    # с уже просчитанными суммами для каждого кошелька в формате:
    # { wallet_id => payout_amount }
    def initialize(api_key:, currency:, payout_wallets:)
      @api_key = api_key
      @currency = currency
      @payout_wallets = payout_wallets
    end

    attr_reader :payout_wallets
    attr_accessor :payout_id


    def create_payout(amount:, address:, fee:)
      raise 'Payout amount > total amount' if payout_wallets.values.sum > amount
      raise 'Payout amount < total amount' if payout_wallets.values.sum < amount

      payout = Payout.new(amount: amount, address: address, fee: fee)

      payout_wallets.each do |wallet_id, payout_amount|
        payout.payout_payments.new(wallet_id: wallet_id, amount: payout_amount)
      end

      payout.save!
      @payout_id = payout.id
    end

    def make_payout!
      response = client.make_payout(query: api_query)
      raise "Can't process payout: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.pay!(txid: response[:payload][:txid])
    end

    def refresh_status!
      return if payout.pending?

      response = client.transaction_details(payout.txid)
      raise "Can't get transaction details: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.update!(confirmations: response[:payload][:confirmations])

      payout.confirmed! if payout.complete_payout?
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_reader :api_key, :currency

    def client
      @client ||= begin
        PayoutClient.new(api_key: api_key, currency: currency)
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
      payout.payout_payments.map do |payment|
        { address: payment.wallet.address, value: payment.amount }
      end
    end

    def outputs
      [{ address: payout.destination_address, value: payout.amount }]
    end

    def wifs
      payout.payout_payments.map do |payment| 
        payment.wallet.wif
      end
    end
  end
end
