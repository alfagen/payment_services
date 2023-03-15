# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

# Адаптер выполняющий запрос на специфичный API-клиент для непосредственной выплаты
#

class PaymentServices::Base
  class PayoutAdapter
    include Virtus.model strict: true

    attribute :wallet_transfers # , Array[WalletTransfer]

    delegate :payment_system, to: :wallet

    # amount - сумма выплаты (Money)
    # transaction_id - идентификатор транзакции (платежки) для записи в журнал на внешнем API
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:)
      raise unless amount.is_a? Money

      make_payout(
        amount: amount,
        payment_card_details: payment_card_details,
        transaction_id: transaction_id,
        destination_account: destination_account
      )
    end

    protected

    def api_keys
      @api_keys ||= begin
        class_name = class.name.delete_suffix('::PayoutAdapter')
        PaymentServiceApiKey.find_by(payment_service_name: class_name) || raise "Ключи для #{class_name} не заведены"
      end
    end

    def api_key
      api_keys.outcome_api_key
    end

    def api_secret
      api_keys.outcome_api_secret
    end

    private

    def make_payout(*)
      raise 'not implemented'
    end

    # NOTE: для адаптеров, которые использую один кошелек для выплат
    def wallet
      wallet_transfers.first.wallet
    end
  end
end
