# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::AppexMoney
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    PAYOUT_NUMBER_PREFIX = 'Kassa_payout_'

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

      begin
        response = client.get(params: { number: "#{PAYOUT_NUMBER_PREFIX}#{payout_number}" })
      rescue Net::ReadTimeout => error
        retry
      end
      raise "Can't get order details: #{response[:errortext]}" if response.dig(:errortext)

      payout.update!(status: response[:status]) if response[:status]
      payout.confirm! if payout.success?
      payout.fail! if payout.status_failed?

      response
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    def payout_number
      @payout_number ||= OrderPayout.find(payout.order_payout_id).order.public_id
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout_id = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id).id
      routes_helper = Rails.application.routes.url_helpers

      params = {
        amount: amount.to_d.round(2).to_s,
        amountcurr: wallet.currency.to_s.upcase,
        number: "#{PAYOUT_NUMBER_PREFIX}#{payout_number}",
        operator: wallet.merchant_id,
        params: destination_account,
        callback_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/appex_money/confirm_payout"
      }
      begin
        response = client.create(params: params)
      rescue Net::ReadTimeout => error
        retry
      end
      raise "Can't process payout: #{response[:errortext]}" if response.dig(:errortext)

      payout.pay!(number: response[:number]) if response[:number]
    end

    def client
      @client ||= begin
        Client.new(
          num_ps: wallet.num_ps,
          first_secret_key: wallet.api_key,
          second_secret_key: wallet.api_secret
        )
      end
    end
  end
end
