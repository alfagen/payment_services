# frozen_string_literal: true

require_relative 'payout'
require_relative 'transaction'

class PaymentServices::PaylamaCrypto
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

      raw_transaction = client.payment_status(payment_id: payout.withdrawal_id, type: 'withdraw')
      raise "Can't get payment information: #{raw_transaction['cause']}" unless raw_transaction['ID']

      transaction = Transaction.build_from(raw_transaction)
      payout.update_state_by_transaction(transaction)
      raw_transaction
    end

    private

    attr_reader :payout
    delegate :outcome_api_key, :outcome_api_secret, to: :api_wallet
    delegate :token_network, to: :payment_system
    delegate :payment_system, to: :api_wallet

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.process_crypto_payout(params: payout_params)
      raise "Can't create payout: #{response['cause']}" unless response['ID']

      payout.pay!(withdrawal_id: response['ID'])
    end

    def payout_params
      {
        amount: payout.amount.to_f,
        currency: currency,
        address: payout.destination_account
      }
    end

    def currency
      @currency ||= PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: api_wallet.currency, token_network: token_network).provider_crypto_currency
    end

    def outcome_payment_system
      @outcome_payment_system ||= wallet.payment_system
    end

    def api_wallet
      @api_wallet ||= outcome_payment_system.wallets.find_by!(name_group: Invoicer::WALLET_NAME_GROUP)
    end

    def client
      @client ||= PaymentServices::Paylama::Client.new(api_key: outcome_api_key, secret_key: outcome_api_secret)
    end
  end
end
