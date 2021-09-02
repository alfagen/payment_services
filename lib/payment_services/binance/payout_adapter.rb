# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Binance
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    INVOICED_CURRENCIES = %w[XRP XEM]
    Error = Class.new StandardError
    PayoutCreateRequestFailed = Class.new Error
    WithdrawHistoryRequestFailed = Class.new Error

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

      response = client.withdraw_history(currency: payout.amount_currency, network: payout.network)
      raise WithdrawHistoryRequestFailed, "Can't get withdraw history: #{response['msg']}" if response.is_a? Hash

      transaction = find_transaction_of(payout: payout, transactions: response)
      return if transaction.nil?

      payout.update_state_by_provider(transaction['status'])
      transaction
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      payout_params = {
        coin: payout.amount_currency,
        amount: amount.to_d,
        address: destination_account,
        network: payout.network
      }
      payout_params[:addressTag] = payout.order_fio_out if invoice_required?
      response = client.create_payout(params: payout_params)
      raise PayoutCreateRequestFailed, "Can't create payout: #{response['msg']}" if response['code']

      payout.pay!(withdraw_id: response['id'])
    end

    def find_transaction_of(payout:, transactions:)
      transactions.find do |transaction|
        transaction['id'] == payout.withdraw_id && transaction['amount'].to_d == payout.amount.to_d
      end
    end

    def invoice_required?
      INVOICED_CURRENCIES.include?(wallet.currency.to_s)
    end

    def client
      @client ||= begin
        Client.new(api_key: wallet.api_key, secret_key: wallet.api_secret)
      end
    end
  end
end
