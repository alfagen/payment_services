# frozen_string_literal: true


module PaymentServices
  class Wallex
    class Payout < ::PaymentServices::Base::FiatPayout
      SUCCESS_PROVIDER_STATE = 3
      FAILED_PROVIDER_STATE  = 2

      self.table_name = 'wallex_payouts'

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
