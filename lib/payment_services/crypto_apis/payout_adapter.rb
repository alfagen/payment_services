# frozen_string_literal: true

require_relative 'payout'
require_relative 'payout_client'

class PaymentServices::CryptoApis
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
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

    def make_payout(amount:, destination_account:)
      payout = Payout.create!(amount: amount, address: destination_account, fee: client.transactions_average_fee)
      @payout_id = payout.id

      response = client.make_payout(payout: payout, wallet: wallet)
      raise "Can't process payout: #{response[:meta][:error][:message]}" if response.dig(:meta, :error, :message)

      payout.pay!(txid: response[:payload][:txid]) if response[:payload][:txid]
    end

    def client
      @client ||= begin
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        PayoutClient.new(api_key: api_key, currency: wallet.currency.to_s.downcase)
      end
    end
  end
end
