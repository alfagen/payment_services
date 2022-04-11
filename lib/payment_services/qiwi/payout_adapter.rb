# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'client'
# Сервис выплаты на QIWI. Выполняет запрос на QIWI-Клиент.
#
class PaymentServices::QIWI
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    # TODO: заменить на before_ ?
    #
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:)
      raise 'Можно делать выплаты только в рублях' unless amount.currency == RUB
      raise 'Кошелек должен быть рублевый' unless wallet.currency == RUB

      super
    end

    private

    # rubocop:disable Lint/UnusedMethodArgument
    def make_payout(amount:, payment_card_details:, transaction_id:, destination_account:)
      # rubocop:enable Lint/UnusedMethodArgument

      client.create_payout(
        id: transaction_id,
        amount: amount.to_f,
        destination_account: destination_account
      )
    end

    def client
      @client ||= Client.new phone: wallet.qiwi_phone, token: wallet.outcome_api_key
    end
  end
end
