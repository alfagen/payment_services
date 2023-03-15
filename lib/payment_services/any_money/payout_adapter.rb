# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::AnyMoney
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      make_payout(
        amount: amount,
        destination_account: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      @payout_id = payout_id
      return if payout.pending?

      params = {
        externalid: payout.externalid.to_s
      }

      response = client.get(params: params)
      raise "Can't get order details: #{response[:error][:message]}" if response.dig(:error)

      result = response[:result]
      payout.update!(status: result[:status]) if result[:status]
      payout.confirm! if payout.success?
      payout.fail! if payout.status_failed?

      result
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout_id = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id).id

      params = {
        amount: amount.to_s,
        externalid: @payout_id.to_s,
        out_curr: wallet.currency.to_s.upcase,
        payway: wallet.payment_system.payway,
        payee: destination_account
      }
      response = client.create(params: params)
      raise "Can't process payout: #{response[:error][:message]}" if response.dig(:error)

      result = response[:result]
      payout.pay!(externalid: result[:externalid]) if result[:externalid]
    end

    def client
      @client ||= begin
        Client.new(merchant_id: wallet.merchant_id, api_key: api_key)
      end
    end
  end
end
