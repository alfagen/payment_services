# frozen_string_literal: true

class PaymentServices::Transfera
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 'PAID'
    FAILED_PROVIDER_STATE   = 'CANCELLED'

    self.table_name = 'transferas_invoices'

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
