# frozen_string_literal: true

class PaymentServices::JustPays
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE = 'OrderCompleted'
    FAILED_PROVIDER_STATE  = 'OrderCanceled'

    self.table_name = 'just_pays_invoices'

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
