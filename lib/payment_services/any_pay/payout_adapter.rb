# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::AnyPay
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    PAYOUT_TYPE = 'qiwi'
    COMMISSION_PAYEER = 'balance'

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

      provider_payout = client.payout(withdrawal_id: payout.withdrawal_id)
      payout.update_state_by_provider(transaction['status']) if provider_payout
      provider_payout
    end

    private

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(params: payout_params)

      payout.pay!(withdrawal_id: response['transaction_id'])
    end

    def payout_params
      {
        payout_id: payout.order_payout_id,
        payout_type: PAYOUT_TYPE,
        amount: payout.amount.to_f,
        wallet: payout.destination_account[1..-1],
        commission_type: COMMISSION_PAYEER
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
