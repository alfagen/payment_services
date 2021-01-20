# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::AnyMoney
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:)
      make_payout(
        amount: amount,
        destination_account: destination_account
      )
    end

    def refresh_status!
      return if payout.pending?

      response = client.get(payout.externalid)
      raise "Can't get order details: #{response[:error][:message]}" if response.dig(:error)

      payout.update!(status: response[:status]) if response[:status]

      payout.confirm! if payout.complete_payout?
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, destination_account:)
      @payout_id = Payout.create!(amount: amount, destination_account: destination_account).id

      params = {
        amount: amount.to_s
        externalid: @payout_id.to_s,
        out_curr: wallet.currency.to_s.upcase,
        payway: wallet.payment_system.name,
        payee: destination_account
      }
      response = client.create(params: params)
      raise "Can't process payout: #{response[:error][:message]}" if response.dig(:error)

      payout.pay!(externalid: @payout_id.to_s) if response[:externalid]
    end

    def client
      @client ||= begin
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        Client.new(merchant_id: wallet.merchant_id, api_key: api_key)
      end
    end
  end
end
