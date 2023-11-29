# frozen_string_literal: true

class PaymentServices::BestApi
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 'fully paid'
    FAILED_PROVIDER_STATE   = 'trade archived'

    self.table_name = 'best_api_invoices'

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
