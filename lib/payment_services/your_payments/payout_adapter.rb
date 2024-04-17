# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::YourPayments
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

      transaction = client.transaction(transaction_id: payout.withdrawal_id)
      payout.update_state_by_provider(transaction['status'])
      transaction
    end

    private

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_provider_transaction(params: payout_params)
      raise Error, "Can't create payout: #{response}" unless response['order_id']

      payout.pay!(withdrawal_id: response['order_id'])
    end

    def payout_params
      {
        type: 'sell',
        amount: payout.amount_cents,
        currency: payout.currency.to_s,
        method_type: method_type,
        customer_id: order.user_id.to_s,
        invoice_id: order.public_id.to_s,
        sell_details: {
          receiver: payout.destination_account,
          bank: provider_bank
        }
      }
    end

    def provider_bank
      resolver = PaymentServices::Base::P2pBankResolver.new(adapter: self)
      sbp_payment? ? resolver.sbp_bank : resolver.card_bank
    end

    def method_type
      sbp_payment? ? Invoicer::SBP_METHOD_TYPE : Invoicer::CARD_METHOD_TYPE
    end

    def sbp_payment?
      @sbp_payment ||= order.outcome_unk.present?
    end

    def order
      @order ||= OrderPayout.find(payout.order_payout_id).order
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
