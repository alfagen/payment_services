# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require_relative 'client'
require_relative 'payout'
# Сервис выплаты на BlockIo. Выполняет запрос на BlockIo-Клиент.
#
class PaymentServices::BlockIo
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    MIN_PAYOUT_AMOUNT = 0.00002 # Block.io restriction
    ALLOWED_CURRENCIES = %w(BTC LTC).freeze
    RESPONSE_SUCCESS = 'success'

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
      @payout_id = payout_id
      return if payout.pending?

      response = client.transactions(address: wallet.account)
      raise response.to_s unless response['status'] == RESPONSE_SUCCESS

      transaction = response['data']['txs'].find do |transaction|
        transaction['txid'] == payout.transaction_id
      end
      return if transaction.nil?

      update_payout_details(transaction)
      payout.confirm! if payout.confirmed?
      transaction
    end

    def payout
      @payout ||= Payout.find_by(id: payout_id)
    end

    private

    attr_accessor :payout_id

    def make_payout(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      @payout_id = create_payout!(amount: amount, address: destination_account, order_payout_id: order_payout_id).id
      response = client.make_payout(address: destination_account, amount: amount.format(decimal_mark: '.', symbol: nil), nonce: transaction_id)
      transaction_id = response.dig('data', 'txid')
      raise response.to_s unless transaction_id

      payout.pay!(transaction_id: transaction_id)
    end

    def update_payout_details(transaction)
      payout.transaction_created_at ||= Time.at(transaction['time']).to_datetime.utc
      payout.fee = transaction['total_amount_sent'].to_f - payout.amount.to_f
      payout.confirmations = transaction['confirmations']

      payout.save!
    end

    def create_payout!(amount:, address:, order_payout_id:)
      Payout.create!(amount: amount, address: address, order_payout_id: order_payout_id)
    end

    def client
      @client ||= Client.new(api_key: wallet.outcome_api_key, pin: wallet.outcome_api_secret)
    end
  end
end
