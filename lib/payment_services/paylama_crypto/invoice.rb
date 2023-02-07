# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Invoice < ::PaymentServices::Paylama::Invoice
    workflow_column :state
    workflow do
      state :pending do
        event :has_transaction, transitions_to: :with_transaction
      end
      state :with_transaction do
        on_entry do
          order.make_reserve!
        end
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount)
        end
      end
      state :cancelled
    end

    def update_state_by_transaction(transaction)
      raise "#{amount.to_f} is needed. But #{transaction.amount} has come." if transaction.valid_amount?(amount)
      has_transaction! if pending?
      update!(
        provider_state: transaction.status, 
        transaction_created_at: transaction.created_at,
        fee: transaction.fee
      )

      pay!(payload: transaction) if transaction.succeed?
      cancel! if transaction.failed?
    end

    private

    def pay(payload:)
      update(payload: payload)
    end
  end
end
