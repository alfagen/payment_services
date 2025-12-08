# frozen_string_literal: true


module PaymentServices
  class JustPays
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATE = 'OrderCompleted'
      FAILED_PROVIDER_STATE  = 'OrderCanceled'

      self.table_name = 'just_pays_invoices'

      monetize :amount_cents, as: :amount

      def can_be_confirmed?(income_money:)
        pending? && income_money == amount
      end

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
