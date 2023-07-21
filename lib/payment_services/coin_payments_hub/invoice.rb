# frozen_string_literal: true

class PaymentServices::CoinPaymentsHub
  class Invoice < ::PaymentServices::Base::CryptoInvoice
    INITIAL_PROVIDER_STATE  = 'wait'

    self.table_name = 'coin_payments_hub_invoices'

    monetize :amount_cents, as: :amount

    def update_state_by_transaction!(transaction)
      validate_transaction_amount!(transaction: transaction)

      bind_transaction! if pending?
      update!(
        provider_state: transaction.status,
        transaction_id: transaction.transaction_id
      )
      pay!(payload: transaction) if transaction.succeed?
      cancel! if transaction.failed?
    end

    def transaction_created_at
      nil
    end

    private

    delegate :income_payment_system, to: :order
    delegate :token_network, to: :income_payment_system

    def validate_transaction_amount!(transaction:)
      raise "#{amount.to_f} #{amount_currency} is needed. But #{transaction.amount} #{transaction.currency} has come." unless transaction.valid_amount?(amount.to_f, amount_currency)
    end
  end
end
