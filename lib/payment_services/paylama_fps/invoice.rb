# frozen_string_literal: true

class PaymentServices::PaylamaFps
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 'Succeed'
    FAILED_PROVIDER_STATE   = 'Failed'

    self.table_name = 'paylama_fps_invoices'

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
