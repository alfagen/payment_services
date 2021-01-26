# frozen_string_literal: true

require_relative 'payout'
require_relative 'payout_client'

class PaymentServices::CryptoApis
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:)
      raise 'amount is not a Money' unless amount.is_a? Money

      make_payout(
        amount: amount,
        address: destination_account
      )
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

    attr_accessor :payout_id

    def make_payout(amount:, address:)
      fee = transaction_fee
      raise "Can't get fee" if fee == 0.0

      @payout_id = Payout.create!(amount: amount, address: address, fee: fee).id

      response = client.make_payout(payout: payout, wallet: wallet)
      raise "Can't process payout: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.pay!(txid: response[:payload][:txid]) if response[:payload][:txid]
    end

    def transaction_fee
      response = client.transactions_average_fee
      raise "Can't get transaction fee: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payload = response[:payload]
      fee = payload[:average].to_f
      fee = payload[:recommended].to_f if fee == 0.0
      fee
    end

    def client
      @client ||= begin
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        PayoutClient.new(api_key: api_key, currency: wallet.currency.to_s.downcase)
      end
    end
  end
end
