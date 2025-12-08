# frozen_string_literal: true

module PaymentServices
  class Paycraft
    class Payout < ::PaymentServices::Base::FiatPayout
      SUCCESS_PROVIDER_STATE = 2
      FAILED_PROVIDER_STATE  = 3

      self.table_name = 'paycraft_payouts'

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
