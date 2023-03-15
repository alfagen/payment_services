# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Binance
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError
    PayoutCreateRequestFailed = Class.new Error
    WithdrawHistoryRequestFailed = Class.new Error

    delegate :outcome_transaction_fee_amount, to: :payment_system

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

      response = client.withdraw_history(currency: payout.amount_currency, network: payout.token_address)
      raise WithdrawHistoryRequestFailed, "Can't get withdraw history: #{response['msg']}" if withdraw_history_response_failed?(response)

      transaction  = response.find { |t| matches?(payout: payout, transaction: t) }
      payout.update_state_by_provider(transaction['status']) if transaction.present?
      transaction
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      payout_params = {
        coin: payout.amount_currency,
        amount: amount.to_d + (outcome_transaction_fee_amount || 0),
        address: destination_account,
        network: payout.token_address
      }
      payout_params[:addressTag] = payout.additional_info if payout.has_additional_info?
      response = client.create_payout(params: payout_params)
      raise PayoutCreateRequestFailed, "Can't create payout: #{response['msg']}" if create_payout_response_failed?(response)

      payout.pay!(withdraw_id: response['id'])
    end

    def withdraw_history_response_failed?(response)
      response.is_a? Hash
    end

    def create_payout_response_failed?(response)
      response['code'].present?
    end

    def matches?(payout:, transaction:)
      transaction['id'] == payout.withdraw_id && transaction['amount'].to_d == payout.amount.to_d
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
