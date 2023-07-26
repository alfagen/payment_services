# frozen_string_literal: true

class PaymentServices::MoneyGate
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 4
    FAILED_PROVIDER_STATE   = 2

    self.table_name = 'money_gate_invoices'

    monetize :amount_cents, as: :amount

    private

    def provider_succeed?
      provider_state == SUCCESS_PROVIDER_STATE
    end

    def provider_failed?
      provider_state == FAILED_PROVIDER_STATE
    end
  end
end
