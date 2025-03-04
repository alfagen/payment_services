# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Capitalist
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      make_payout(
        amount: amount,
        destination_account: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      payout = Payout.find(payout_id)
      return if payout.pending?

      transaction = client.transaction(payout_id: payout.withdrawal_id)
      payout.update_state_by_provider(transaction['state'])
      transaction
    end

    private

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(params: payout_params)
      raise Error, response['message'] unless response['code'] == 0

      payout.pay!(withdrawal_id: response['data']['id'])
    end

    def payout_params
      order = OrderPayout.find(payout.order_payout_id).order
      number = sbp? ? order.outcome_phone[1..-1] : payout.destination_account

      params = {
        amount: "%.2f" % payout.amount.to_f,
        number: number,
        order_id: order.public_id.to_s,
        service: service
      }
      params[:customer_code] = sbp_bank if sbp?
      params
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
