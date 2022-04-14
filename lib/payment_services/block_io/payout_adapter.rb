# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require_relative 'client'
# Сервис выплаты на BlockIo. Выполняет запрос на BlockIo-Клиент.
#
class PaymentServices::BlockIo
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    MIN_PAYOUT_AMOUNT = 0.00002 # Block.io restriction
    ALLOWED_CURRENCIES = %w(BTC LTC).freeze

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      raise "Можно делать выплаты только в #{ALLOWED_CURRENCIES.join(', ')}" unless ALLOWED_CURRENCIES.include?(amount.currency.to_s)
      raise "Кошелек должен быть в  #{ALLOWED_CURRENCIES.join(', ')}" unless ALLOWED_CURRENCIES.include?(wallet.currency.to_s)
      raise 'Валюты должны совпадать' unless amount.currency.to_s == wallet.currency.to_s
      raise "Минимальная выплата #{MIN_PAYOUT_AMOUNT}, к выплате #{amount}" if amount.to_f < MIN_PAYOUT_AMOUNT

      make_payout(
        amount: amount,
        payment_card_details: payment_card_details,
        transaction_id: transaction_id,
        destination_account: destination_account
      )
    end

    private

    # rubocop:disable Lint/UnusedMethodArgument
    def make_payout(amount:, payment_card_details:, transaction_id:, destination_account:)
      # rubocop:enable Lint/UnusedMethodArgument
      client = Client.new(api_key: wallet.outcome_api_key, pin: wallet.outcome_api_secret)
      client.make_payout(address: destination_account, amount: amount.format(decimal_mark: '.', symbol: nil), nonce: transaction_id)
    end
  end
end
