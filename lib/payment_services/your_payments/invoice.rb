# frozen_string_literal: true

class PaymentServices::YourPayments
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATES  = %w(FINISHED_SUCCESS FINISHED_SUCCESS_RECALC)
    FAILED_PROVIDER_STATES   = %w(FINISHED_REJECTED FINISHED_EXPIRED FINISHED_CANCELED)

    self.table_name = 'your_payments_invoices'

    monetize :amount_cents, as: :amount

    private

    def provider_succeed?
      provider_state.in? SUCCESS_PROVIDER_STATES
    end

    def provider_failed?
      provider_state.in? FAILED_PROVIDER_STATES
    end
  end
end
