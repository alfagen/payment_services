# frozen_string_literal: true


module PaymentServices
  class FireKassa
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATES  = %w(paid overpaid)
      FAILED_PROVIDER_STATE    = 'expired'

      self.table_name = 'fire_kassa_invoices'

      monetize :amount_cents, as: :amount

      private

      def provider_succeed?
        provider_state.in? SUCCESS_PROVIDER_STATES
      end

      def provider_failed?
        provider_state == FAILED_PROVIDER_STATE
      end
    end
  end
end
