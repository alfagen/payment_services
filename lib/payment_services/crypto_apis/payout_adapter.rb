# frozen_string_literal: true

require_relative 'payout'
require_relative 'payout_client'

class PaymentServices::CryptoApis
  class PayoutAdapter
    def initialize(wallet:)
      @wallet = wallet
    end

    attr_accessor :payout_id

    def create_payout(amount:, address:)
      payout = Payout.create!(amount: amount, address: address, fee: client.transactions_average_fee)

      @payout_id = payout.id
    end

    def make_payout!
      response = client.make_payout(query: api_query)
      raise "Can't process payout: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.pay!(txid: response[:payload][:txid]) if response[:payload][:txid]
    end

    def refresh_status!
      return if payout.pending?

      response = client.transaction_details(payout.txid)
      raise "Can't get transaction details: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.update!(confirmations: response[:payload][:confirmations]) if response[:payload][:confirmations]

      payout.confirm! if payout.complete_payout?
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_reader :wallet

    def client
      @client ||= begin
        PayoutClient.new(api_key: wallet.api_key, currency: wallet.currency.to_s.downcase)
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
      [{ address: wallet.address, value: payout.amount }]
    end

    def outputs
      [{ address: payout.address, value: payout.amount }]
    end

    def wifs
      [ wallet.wif ]
    end
  end
end
