# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Cryptomus
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError
    USDT_NETWORK_TO_CURRENCY = {
      'trc20' => 'TRON',
      'erc20' => 'ETH',
      'ton'   => 'TON',
      'sol'   => 'SOL',
      'POLYGON' => 'POLYGON',
      'bep20' => 'BSC'
    }.freeze

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

      transaction = client.payout(params: { uuid: payout.withdrawal_id } )
      payout.update(txid: transaction.dig('result', 'txid'))
      payout.update_state_by_provider(transaction.dig('result', 'status'))
      transaction
    end

    private

    attr_reader :payout

    delegate :outcome_from_personal_account, to: :outcome_payment_system
    delegate :outcome_payment_system, to: :order

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      if outcome_from_personal_account
        currency = payout.amount_currency.to_s
        currency = 'DASH' if currency == 'DSH'
        response = client.transfer_to_business(params: { amount: payout.amount.to_f.to_s, currency: currency })
        raise Error, "Can't create transfer: #{response['message']}" if response['message'].present?
      end
      response = client.create_payout(params: payout_params)
      raise Error, "Can't create payout: #{response['message']}" if response['message']

      payout.pay!(withdrawal_id: response.dig('result', 'uuid'))
    end

    def payout_params
      currency = payout.amount_currency.to_s.downcase.inquiry
      currency = 'dash'.inquiry if currency.dsh?
      params = {
        amount: payout.amount.to_f.to_s,
        currency: currency.upcase,
        order_id: order.public_id.to_s,
        address: payout.destination_account,
        is_subtract: true
      }
      params[:memo] = order.outcome_fio if currency.ton?
      params[:network] = currency.usdt? || currency.bnb? ? network(currency) : currency.upcase
      params
    end

    def transfer_to_business
      currency = payout.amount_currency.to_s
      currency = 'DASH' if currency == 'DSH'
      response = client.transfer_to_business(params: { amount: payout.amount.to_f.to_s, currency: currency })
      raise Error, "Can't create transfer: #{response['message']}" if response['message'].present?
    end

    def network(currency)
      return 'BSC' if currency.bnb?

      USDT_NETWORK_TO_CURRENCY[order.outcome_payment_system.token_network] || 'USDT'
    end

    def order
      @order ||= OrderPayout.find(payout.order_payout_id).order
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
