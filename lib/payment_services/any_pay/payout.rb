# frozen_string_literal: true


module PaymentServices
  class AnyPay
    class Payout < ::PaymentServices::Base::FiatPayout
      SUCCESS_PROVIDER_STATE  = 'paid'
      FAILED_PROVIDER_STATES   = %w(canceled blocked)

      self.table_name = 'any_pay_payouts'

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
