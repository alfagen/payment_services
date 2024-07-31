# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Cryptomus
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

      transaction = client.payout(params: { uuid: payout.withdrawal_id } )
      payout.update(txid: transaction.dig('result', 'txid'))
      payout.update_state_by_provider(transaction.dig('result', 'status'))
      transaction
    end

    private

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(params: payout_params)
      raise Error, "Can't create payout: #{response['message']}" if response['message']

      payout.pay!(withdrawal_id: response.dig('result', 'uuid'))
    end

    def payout_params
      order = OrderPayout.find(payout.order_payout_id).order
      params = {
        amount: payout.amount.to_f.to_s,
        currency: payout.amount_currency.to_s,
        order_id: order.public_id.to_s,
        address: payout.destination_account,
        is_subtract: true,
        network: payout.amount_currency.to_s
      }
      params[:memo] = order.outcome_fio if payout.amount_currency.to_s.downcase.inquiry.ton?
      params
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
