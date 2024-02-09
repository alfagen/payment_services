# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

module PaymentServices::Wallex
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    PAYOUT_SUCCESS_STATE = 'success'

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
      payout.update_state_by_provider(transaction.dig('item', 'status')) if transaction
      transaction
    end

    private

    delegate :card_bank, :sbp_bank, :sbp?, to: :bank_resolver

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(params: payout_params)
      raise response['error'] unless response['status'] == PAYOUT_SUCCESS_STATE

      payout.pay!(withdrawal_id: response['id'])
    end

    def payout_params
      params = {
        uuid: "#{Rails.env}_#{payout.id}",
        amount: payout.amount.to_f.to_s,
        currency: 'rub',
        type: 'fiat',
        bank: card_bank,
        number: payout.destination_account,
        fiat: 'rub'
      }
      params[:bankCode] = sbp_bank if sbp?
      params
    end

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
