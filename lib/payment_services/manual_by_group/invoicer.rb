# frozen_string_literal: true

class PaymentServices::ManualByGroup
  class Invoicer < ::PaymentServices::Base::Invoicer
    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      wallet = income_payment_system.select_next_wallet!(wallets_available_for_transfers.income.where(name_group: wallets_name_group))
      PaymentServices::Base::Wallet.new(
        address: wallet&.account,
        name: wallet&.name,
        memo: wallet&.memo
      )
    end

    def create_invoice(money)
      true
    end

    def async_invoice_state_updater?
      false
    end

    def invoice
      nil
    end

    private

    delegate :wallets_name_group, :wallets_available_for_transfers, to: :income_payment_system
    delegate :income_payment_system, to: :order
  end
end
