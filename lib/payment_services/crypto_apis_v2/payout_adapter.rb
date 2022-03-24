# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::CryptoApisV2
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    FAILED_PAYOUT_STATUSES = %w(failed rejected)
    XRP_SUCCESS_TRANSACTION_STATUS = 'tesSUCCESS'

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

      unless payout.txid
        response = client.request_details(payout.request_id)
        raise response['error']['message'] if response['error']

        transaction = response['data']['item']
        payout.fail! if FAILED_PAYOUT_STATUSES.include?(transaction['transactionRequestStatus'])

        payout.update!(txid: transaction['transactionId']) if transaction['transactionId']
      else
        response = client.transaction_details(payout.txid)
        raise response['error']['message'] if response['error']

        update_payout_details(response['data']['item'])
        payout.confirm! if payout.confirmed?
      end

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
      raise response['error']['message'] if response['error']

      request_id = response['data']['item']['transactionRequestId']
      payout.pay!(request_id: request_id)
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

    def update_payout_details(transaction)
      payout.confirmed = confirmed?(transaction)
      payout.fee ||= transaction['fee']['amount'].to_f

      payout.save!
    end

    def confirmed?(transaction)
      return transaction['isConfirmed'] if transaction['isConfirmed']
      return true if transaction['status'] == XRP_SUCCESS_PAYOUT_STATUS

      false
    end
  end
end
