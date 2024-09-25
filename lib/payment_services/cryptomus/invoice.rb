# frozen_string_literal: true

class PaymentServices::Cryptomus
  class Invoice < ::PaymentServices::Base::FiatInvoice
    # SUCCESS_PROVIDER_STATES = %w(paid paid_over wrong_amount_waiting wrong_amount)
    # FAILED_PROVIDER_STATES  = %w(fail cancel system_fail)
    SUCCESS_PROVIDER_STATES = %w(paid paid_over)
    FAILED_PROVIDER_STATES  = %w(fail cancel system_fail wrong_amount_waiting wrong_amount) 

    self.table_name = 'cryptomus_invoices'

    monetize :amount_cents, as: :amount

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount, hash: transaction_id)
        end
      end
      state :cancelled
    end

    def transaction_created_at
      nil
    end

    private

    def provider_succeed?
      provider_state.in? SUCCESS_PROVIDER_STATES
    end

    def provider_failed?
      provider_state.in? FAILED_PROVIDER_STATES
    end
  end
end
