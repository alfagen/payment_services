# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::AppexMoney
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
        number: @payout_id.to_s
      }

      response = client.get(params: params)
      raise "Can't get order details: #{response[:errortext]}" if response.dig(:errortext)

      payout.update!(status: response[:status]) if response[:status]
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
        amount: amount.to_d,
        amountcurr: wallet.currency.to_s.upcase,
        number: "Invoice#{@payout_id}",
        operator: wallet.payment_system.payway,
        params: destination_account
      }
      response = client.create(params: params)
      raise "Can't process payout: #{response[:errortext]}" if response.dig(:errortext)

      payout.pay!(number: response[:number]) if response[:number]
    end

    def client
      @client ||= begin
        Client.new(
          account_id: wallet.merchant_id,
          first_secret_key: wallet.api_key,
          second_secret_key: wallet.secretKey
        )
      end
    end
  end
end
