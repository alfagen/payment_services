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
    ALLOWED_CURRENCIES = %w(btc ltc doge).freeze
    DEFAULT_FEE_PRIORITY = 'medium'
    BTC_FEE_PRIORITY = 'medium'
    Error = Class.new StandardError
    TansactionIdNotReceived = Class.new Error

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      amount_currency = amount.currency.to_s.downcase
      raise "Можно делать выплаты только в #{ALLOWED_CURRENCIES.join(', ')}" unless ALLOWED_CURRENCIES.include?(amount_currency)
      raise "Кошелек должен быть в  #{ALLOWED_CURRENCIES.join(', ')}" unless ALLOWED_CURRENCIES.include?(wallet_currency)
      raise 'Валюты должны совпадать' unless amount_currency == wallet_currency
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

      transaction = build_transaction(payout)
      payout.update_payout_details!(transaction: transaction)
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
        amount: amount.format(decimal_mark: '.', symbol: nil, thousands_separator: ''),
        nonce: transaction_id,
        fee_priority: fee_priority
      )
      transaction_id = client.extract_transaction_id(response)
      raise TansactionIdNotReceived, response.to_s unless transaction_id

      payout.pay!(transaction_id: transaction_id)
    end

    def find_transaction(txid:, transactions:)
      transactions.find { |transaction| transaction['txid'] == txid }
    end

    def create_payout!(amount:, address:, order_payout_id:)
      Payout.create!(amount: amount, address: address, order_payout_id: order_payout_id)
    end

    def build_transaction(payout)
      wallet_transactions = client.outcome_transactions(address: wallet.account)['data']['txs']
      raw_transaction = find_transaction(txid: payout.transaction_id, transactions: wallet_transactions)

      Transaction.build_from(raw_transaction: raw_transaction)
    end

    def fee_priority
      DEFAULT_FEE_PRIORITY
    end

    def wallet_currency
      @wallet_currency ||= wallet.currency.to_s.downcase.inquiry
    end

    def client
      @client ||= Client.new(api_key: wallet.outcome_api_key, pin: wallet.outcome_api_secret)
    end
  end
end
