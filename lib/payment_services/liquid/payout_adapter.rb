# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Liquid
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      make_payout(
        amount: amount,
        address: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      @payout_id = payout_id
      return if payout.pending?

      response = client.withdrawals
      raise "Can't get payout details: #{response['errors'].to_s}" if response['errors']

      withdrawal = response['models'].find do |withdrawal|
        payout.withdrawal_id == withdrawal.id
      end

      payout.update!(status: withdrawal['state']) if withdrawal
      payout.confirm! if payout.complete_payout?
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, address:, order_payout_id:)
      @payout_id = Payout.create!(amount: amount, address: address, order_payout_id: order_payout_id).id

      payout_params = {
        amount: amount.to_d.round(2),
        address: address,
        payment_id: nil,
        memo_type: nil,
        memo_value: nil
      }
      response = client.make_payout(payout_params)

      # NOTE: there are 2 types of error responses
      errors = response['message'] || response['errors']
      raise "Can't process payout: #{errors.to_s}" if errors
      raise 'Payout was not processed' unless response['id']

      payout.pay!(withdrawal_id: response['id'])
    end

    def client
      @client ||= begin
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        Client.new(currency: wallet.currency.to_s, token_id: wallet.merchant_id.to_i, api_key: api_key)
      end
    end
  end
end
