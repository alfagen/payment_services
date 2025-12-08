# frozen_string_literal: true


module PaymentServices
  class MerchantAlikassa
    class Payout < ::PaymentServices::Base::FiatPayout
      self.table_name = 'merchant_alikassa_payouts'

      monetize :amount_cents, as: :amount

      private

      def provider_succeed?
        provider_state == Invoice::SUCCESS_PROVIDER_STATE
      end

      def provider_failed?
        provider_state.in? Invoice::FAILED_PROVIDER_STATES
      end
    end
  end
end
