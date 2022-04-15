# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require_relative 'client'
require_relative 'payout'
require_relative 'transaction'
# Сервис выплаты на BlockIo. Выполняет запрос на BlockIo-Клиент.
#
class PaymentServices::BlockIo
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    MIN_PAYOUT_AMOUNT = 0.00002 # Block.io restriction
    ALLOWED_CURRENCIES = %w(BTC LTC).freeze
    Error = Class.new StandardError
    TansactionIdNotReceived = Class.new Error

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      raise "Можно делать выплаты только в #{ALLOWED_CURRENCIES.join(', ')}" unless ALLOWED_CURRENCIES.include?(amount.currency.to_s)
      raise "Кошелек должен быть в  #{ALLOWED_CURRENCIES.join(', ')}" unless ALLOWED_CURRENCIES.include?(wallet.currency.to_s)
      raise 'Валюты должны совпадать' unless amount.currency.to_s == wallet.currency.to_s
      raise "Минимальная выплата #{MIN_PAYOUT_AMOUNT}, к выплате #{amount}" if amount.to_f < MIN_PAYOUT_AMOUNT

      make_payout(
        amount: amount,
        payment_card_details: payment_card_details,
        transaction_id: transaction_id,
        destination_account: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      payout = Payout.find(payout_id)
      return if payout.pending? || payout.transaction_id.nil?

      transaction = Transaction.new(api_response: find_transaction(txid: payout.transaction_id, transactions: client.transactions(address: wallet.account)['data']['txs']))
      update_payout_details(payout, transaction)
      payout.confirm! if payout.confirmed?
      transaction
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      payout = create_payout!(amount: amount, address: destination_account, order_payout_id: order_payout_id)
      response = client.make_payout(
        address: destination_account,
        amount: amount.format(decimal_mark: '.', symbol: nil),
        nonce: transaction_id
      )
      transaction_id = client.extract_transaction_id(response)
      raise TansactionIdNotReceived, response.to_s unless transaction_id

      payout.pay!(transaction_id: transaction_id)
    end

    def update_payout_details(payout, transaction)
      payout.transaction_created_at ||= transaction.transaction_created_at
      payout.fee = transaction.total_spend - payout.amount.to_f
      payout.confirmations = transaction.confirmations

      payout.save!
    end

    def find_transaction(txid:, transactions:)
      transactions.find do |transaction|
        transaction['txid'] == txid
      end
    end

    def create_payout!(amount:, address:, order_payout_id:)
      Payout.create!(amount: amount, address: address, order_payout_id: order_payout_id)
    end

    def client
      @client ||= Client.new(api_key: wallet.outcome_api_key, pin: wallet.outcome_api_secret)
    end
  end
end
