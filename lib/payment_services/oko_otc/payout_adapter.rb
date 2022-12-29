# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::OkoOtc
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError
    PayoutCreateRequestFailed = Class.new Error
    WithdrawHistoryRequestFailed = Class.new Error

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

      params = {
        limit: 1,
        offset: 0,
        orderID: payout.withdrawal_id,
        orderType: 'withdraw'
      }
      response = client.payout_status(params: params)

      raise WithdrawHistoryRequestFailed, "Can't get withdraw history: Error Code: #{response['errCode']}" unless response['totalLen']

      payout.update_state_by_provider(provider_state(response))
      response
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      order = OrderPayout.find(order_payout_id).order

      params = {
        sum: amount.to_i,
        currencyFrom: amount.currency.to_s,
        wallet: destination_account,
        bank: amount.currency.to_s,
        cardholder: order.outcome_fio,
        dateOfBirth: order.outcome_operator,
        cardExpiration: card_expiration(order),
        orderUID: "#{order.public_id}-#{order_payout_id}"
      }
      response = client.process_payout(params: params)
      raise PayoutCreateRequestFailed, "Can't create payout: Error Code: #{response['errCode']}" unless response['status']

      payout.pay!(withdrawal_id: response['orderID'])
    end

    def client
      @client ||= begin
        Client.new(api_key: wallet.outcome_api_key, secret_key: wallet.outcome_api_secret)
      end
    end

    def card_expiration(order)
      month, year = order.payment_card_exp_date.split('/')
      year.length == 2 ? "#{month}/20#{year}" : "#{month}/#{year}"
    end

    def provider_state(response)
      response['data'].first.dig('orderStats', 'statusName')
    end
  end
end
