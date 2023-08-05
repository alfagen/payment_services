# frozen_string_literal: true

class PaymentServices::MerchantAlikassa
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 'paid'
    FAILED_PROVIDER_STATES  = %w(cancel fail)

    self.table_name = 'merchant_alikassa_invoices'

    monetize :amount_cents, as: :amount

    private

    def provider_succeed?
      provider_state == SUCCESS_PROVIDER_STATE
    end

    def provider_failed?
      provider_state.in? FAILED_PROVIDER_STATES
    end
  end
end
