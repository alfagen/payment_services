# frozen_string_literal: true


module PaymentServices
  class PandaPay
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATE  = 'completed'
      FAILED_PROVIDER_STATES  = %w(traderNotFound timeout canceled)

      self.table_name = 'panda_pay_invoices'

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
end
