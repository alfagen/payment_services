# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::MerchantAlikassa
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError
    P2P_RUB_SERVICE = 'payment_card_rub'
    SBP_RUB_SERVICE = 'payment_card_sbp_rub'

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

      transaction = client.payout_transaction(payout_id: payout.withdrawal_id)
      payout.update_state_by_provider(transaction['payment_status']) if transaction
      transaction
    end

    private

    delegate :sbp_bank, :sbp?, to: :bank_resolver

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(params: payout_params)
      raise Error, response['message'] if response['errors']

      payout.pay!(withdrawal_id: response['id'])
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

    def service
      sbp? ? SBP_RUB_SERVICE : P2P_RUB_SERVICE
    end

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def order
      OrderPayout.find(payout.order_payout_id).order
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
