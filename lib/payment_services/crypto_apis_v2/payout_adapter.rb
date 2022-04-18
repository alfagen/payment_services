# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'
require_relative 'transaction'

class PaymentServices::CryptoApisV2
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    FAILED_PAYOUT_STATUSES = %w(failed rejected)

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      raise 'amount is not a Money' unless amount.is_a? Money

      make_payout(
        amount: amount,
        address: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      payout = Payout.find(payout_id)
      return if payout.pending?

      unless payout.txid
        response = client.request_details(payout.request_id)
        raise response['error']['message'] if response['error']

        transaction = response['data']['item']
        payout.fail! if FAILED_PAYOUT_STATUSES.include?(transaction['transactionRequestStatus'])
        payout.update!(txid: transaction['transactionId']) if transaction['transactionId']
      else
        response = client.transaction_details(payout.txid)
        raise response['error']['message'] if response['error']

        payout.update_payout_details!(transaction: Transaction.build_from(raw_transaction: response['data']['item']))
      end

      response
    end

    private

    def make_payout(amount:, address:, order_payout_id:)
      payout = create_payout!(amount: amount, address: address, fee: 0, order_payout_id: order_payout_id)

      response = client.make_payout(payout: payout, wallet_transfers: wallet_transfers)
      raise response['error']['message'] if response['error']

      request_id = response['data']['item']['transactionRequestId']
      payout.pay!(request_id: request_id)
    end

    def client
      @client ||= begin
        api_key = wallet.outcome_api_key.presence || wallet.parent&.outcome_api_key
        currency = wallet.currency.to_s.downcase

        Client.new(api_key: api_key, currency: currency)
      end
    end

    def create_payout!(amount:, address:, fee:, order_payout_id:)
      Payout.create!(amount: amount, address: address, fee: fee, order_payout_id: order_payout_id)
    end
  end
end
