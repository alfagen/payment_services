# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::CryptoApisV2
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    delegate :outcome_transaction_fee_amount, to: :payment_system

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      raise 'amount is not a Money' unless amount.is_a? Money

      make_payout(
        amount: amount,
        address: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      @payout_id = payout_id
      return if payout.pending?

      response = client.request_details(payout.txid)
      raise response['error']['message'] if response.dig(:error, :message)

      provider_state = response['data']['item']['transactionRequestStatus']
      payout.update_state_by_provider!(provider_state)
      response
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, address:, order_payout_id:)
      @payout_id = create_payout!(amount: amount, address: address, fee: 0, order_payout_id: order_payout_id).id

      response = client.make_payout(payout: payout, wallet_transfers: wallet_transfers)
      raise response['error']['message'] if response.dig(:error, :message)

      request_id = response['data']['item']['transactionRequestId']
      payout.pay!(txid: request_id)
    end

    def client
      @client ||= begin
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        currency = wallet.currency.to_s.downcase

        Client.new(api_key: api_key, currency: currency)
      end
    end

    def create_payout!(amount:, address:, fee:, order_payout_id:)
      Payout.create!(amount: amount, address: address, fee: fee, order_payout_id: order_payout_id)
    end
  end
end
