# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::PerfectMoney
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
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

      response = client.find_transaction(payment_batch_number: payout.payment_batch_number)
      raise "Can't get withdrawal details" unless response

      payout.confirm! if response['Batch'] == payout.payment_batch_number
      response
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)

      response = client.create_payout(destination_account: destination_account, amount: amount.to_d.round(2), payment_id: payout.build_payment_id)
      raise "Can't process payout: #{response['ERROR']}" if response['ERROR']

      payout.pay!(payment_batch_number: response['PAYMENT_BATCH_NUM']) if response['PAYMENT_BATCH_NUM']
    end

    def client
      @client ||= begin
        Client.new(account_id: wallet.merchant_id, pass_phrase: wallet.api_key, account: wallet.account)
      end
    end
  end
end
