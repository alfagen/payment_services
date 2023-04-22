# frozen_string_literal: true

class PaymentServices::ExPay
  class Invoice < ::PaymentServices::Base::FiatInvoice
    INITIAL_PROVIDER_STATE  = 'ACCEPTED'
    SUCCESS_PROVIDER_STATE  = 'SUCCEED'
    FAILED_PROVIDER_STATE   = 'FAILED'

    self.table_name = 'ex_pay_invoices'

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
