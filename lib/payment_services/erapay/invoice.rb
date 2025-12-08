# frozen_string_literal: true


module PaymentServices
  class Erapay
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATE = '0'

      self.table_name = 'erapay_invoices'

      monetize :amount_cents, as: :amount

      def can_be_confirmed?(income_money:, status:)
        pending? && status == SUCCESS_PROVIDER_STATE && income_money == amount
      end

      private

      def provider_succeed?
        false
      end

      def provider_failed?
        false
      end
    end
  end
end
