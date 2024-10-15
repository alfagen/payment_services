# frozen_string_literal: true

class PaymentServices::XPayProVirtual
  class Invoice < ::PaymentServices::Base::FiatInvoice
    SUCCESS_PROVIDER_STATE  = 'TX_SUCCESS'
    FAILED_PROVIDER_STATES  = %w(TX_CANCELLED TX_EXPIRED)

    self.table_name = 'xpaypro_virtual_invoices'

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
