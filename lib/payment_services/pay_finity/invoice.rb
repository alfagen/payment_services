# frozen_string_literal: true

class PaymentServices::PayFinity
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 'SUCCESS'
    FAILED_PROVIDER_STATE   = 'ERROR'

    self.table_name = 'pay_finity_invoices'

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
