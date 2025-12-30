# frozen_string_literal: true

module PaymentServices
  class Bovapay
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATE = 'successed'
      FAILED_PROVIDER_STATE  = 'failed'

      self.table_name = 'bovapay_invoices'

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
