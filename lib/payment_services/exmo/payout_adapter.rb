# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'
require_relative 'transaction'

class PaymentServices::Exmo
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    INVOICED_CURRENCIES = %w[XRP XEM]
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

      raw_transaction = find_transaction_of(payout: payout, transactions: response['items'])
      return if raw_transaction.nil?

      transaction = Transaction.build_from(raw_transaction: raw_transaction)
      payout.update_payout_details!(transaction: transaction)
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
      payout_params[:invoice] = payout.order_fio if invoice_required?
      payout_params[:amount] = payout_params[:amount].to_i if currency_neo?
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
        Client.new(public_key: wallet.outcome_api_key, secret_key: wallet.outcome_api_secret)
      end
    end

    def invoice_required?
      INVOICED_CURRENCIES.include?(wallet.currency.to_s)
    end

    def currency_neo?
      wallet.currency.to_s == 'NEO'
    end
  end
end
