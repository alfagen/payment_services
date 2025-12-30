# frozen_string_literal: true

module PaymentServices
  class ExPay
    class Invoice < ::PaymentServices::Base::FiatInvoice
      INITIAL_PROVIDER_STATE  = 'ACCEPTED'
      SUCCESS_PROVIDER_STATE  = 'SUCCESS'
      FAILED_PROVIDER_STATE   = 'ERROR'

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
end
