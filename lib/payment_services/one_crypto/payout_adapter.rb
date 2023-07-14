# frozen_string_literal: true

require_relative 'client'
require_relative 'payout'
require_relative 'transaction'

class PaymentServices::OneCrypto
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    INITIAL_PROVIDER_STATE = 'ACCEPTED'

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

      raw_transaction = client.transaction(tracker_id: payout.withdrawal_id)
      transaction = Transaction.build_from(raw_transaction)
      payout.update_state_by_transaction(transaction)
      raw_transaction
    end

    private

    attr_reader :payout

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(params: payout_params)
      raise "Can't create payout: #{response['description']}" unless response['status'] == INITIAL_PROVIDER_STATE

      payout.pay!(withdrawal_id: response['tracker_id'])
    end

    def payout_params
      {
        token: currency,
        amount: payout.amount.to_f,
        client_transaction_id: "#{payout.order_payout_id}-#{payout.id}",
        receiver: payout.destination_account
      }
    end

    def currency
      PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: wallet.currency, token_network: wallet.payment_system.token_network).provider_crypto_currency
    end

    def client
      @client ||= PaymentServices::Paylama::Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
