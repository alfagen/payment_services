# frozen_string_literal: true

module PaymentServices
  class PayForU
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATE  = 'completed'
      FAILED_PROVIDER_STATE   = 'error'

      self.table_name = 'pay_for_u_invoices'

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
end
