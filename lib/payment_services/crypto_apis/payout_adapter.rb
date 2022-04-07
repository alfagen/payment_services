# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::CryptoApis
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    delegate :outcome_transaction_fee_amount, to: :payment_system

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      raise 'amount is not a Money' unless amount.is_a? Money

      make_payout(
        amount: amount,
        address: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      @payout_id = payout_id
      return if payout.pending?

      response = client.transaction_details(payout.txid)

      payout.update!(
        confirmations: response[:payload][:confirmations],
        fee: response[:payload][:fee].to_f
      ) if response[:payload]
      payout.confirm! if payout.success?

      response[:payload]
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, address:, order_payout_id:)
      fee = outcome_transaction_fee_amount || provider_fee
      raise "Fee is too low: #{fee}" if fee < 0.00000001

      @payout_id = create_payout!(amount: amount, address: address, fee: fee, order_payout_id: order_payout_id).id

      response = client.make_payout(payout: payout, wallet_transfers: wallet_transfers)
      raise "Can't process payout: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      # NOTE: hex for: ETH/ETC. txid for: BTC/OMNI/BCH/LTC/DOGE/DASH
      hash = response[:payload][:txid] || response[:payload][:hex]
      raise "Didn't get transaction hash" unless hash

      payout.pay!(txid: hash)
    end

    def provider_fee
      response = client.transactions_average_fee
      raise "Can't get transaction fee: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payload = response[:payload]
      fee = payload[:standard].to_f
      fee = payload[:average].to_f if fee == 0.0
      fee
    end

    def client
      @client ||= begin
        api_key = wallet.outcome_api_key.presence || wallet.parent&.outcome_api_key
        currency = wallet.currency.to_s.downcase

        Client.new(currency: currency).payout.new(api_key: api_key, currency: currency)
      end
    end

    def create_payout!(amount:, address:, fee:, order_payout_id:)
      Payout.create!(amount: amount, address: address, fee: fee, order_payout_id: order_payout_id)
    end
  end
end
