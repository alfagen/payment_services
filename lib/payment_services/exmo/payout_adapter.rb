# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Exmo
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError
    PayoutCreateRequestFailed = Class.new Error
    WalletOperationsRequestFailed = Class.new Error

    delegate :outcome_transaction_fee_amount, to: :payment_system


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

      response = client.wallet_operations(currency: wallet.currency.to_s, type: 'withdrawal')
      raise WalletOperationsRequestFailed, "Can't get wallet operations" unless response['items']

      transaction = find_transaction_of(payout: payout, transactions: response['items'])
      return if transaction.nil?

      payout.update_state_by_provider(transaction['status'])
      transaction
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      payout_params = {
        amount: amount.to_d + (outcome_transaction_fee_amount || 0),
        currency: wallet.currency.to_s,
        address: destination_account
      }
      payout_params[:invoice] = payout.order_fio_out if payout.order_fio_out.present?
      response = client.create_payout(params: payout_params)
      raise PayoutCreateRequestFailed, "Can't create payout: #{response['error']}" unless response['result']

      payout.pay!(task_id: response['task_id'].to_i)
    end

    def find_transaction_of(payout:, transactions:)
      transactions.find do |transaction|
        transaction['order_id'] == payout.task_id && (payout.amount.to_d + (outcome_transaction_fee_amount || 0)) == transaction['amount'].to_d
      end
    end

    def client
      @client ||= begin
        Client.new(public_key: wallet.api_key, secret_key: wallet.api_secret)
      end
    end
  end
end
