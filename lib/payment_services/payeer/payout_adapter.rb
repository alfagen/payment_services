# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Payeer
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
        account: wallet.num_ps,
        merchantId: wallet.merchant_id,
        referenceId: payout.reference_id
      }

      response = client.payout_status(params: params)

      raise "Can't get withdrawal details: #{response['errors']}" if response['errors'].any?

      payout.update!(success_provider_state: response['success'])
      payout.confirm! if payout.success?
      payout.fail! if payout.failed?

      response
    end

    def payout
      @payout ||= Payout.find(payout_id)
    end

    private

    attr_accessor :payout_id

    def order_payout
      @order_payout ||= OrderPayout.find(payout.order_payout_id)
    end

    def reference_id
      "#{order_payout.order.public_id}-#{order_payout.id}"
    end

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout_id = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id).id

      params = {
        account: wallet.num_ps,
        sum: amount.to_d,
        to: destination_account,
        comment: "Перевод по заявке №#{order_payout.order.public_id} на сайте Kassa.cc"
      }
      response = client.create_payout(params: params)

      raise "Can't process payout: #{response['errors']}" if response['errors'].any?

      payout.pay!(reference_id: reference_id)
    end

    def client
      @client ||= begin
        Client.new(api_id: wallet.merchant_id.to_i, api_key: wallet.api_key, currency: wallet.currency.to_s)
      end
    end
  end
end
