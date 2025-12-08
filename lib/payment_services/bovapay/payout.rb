# frozen_string_literal: true


module PaymentServices
  class Bovapay
    class Payout < ::PaymentServices::Base::FiatPayout
      SUCCESS_PROVIDER_STATE = 'paid'
      FAILED_PROVIDER_STATE  = 'failed'

      self.table_name = 'bovapay_payouts'

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
