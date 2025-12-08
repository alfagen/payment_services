# frozen_string_literal: true


module PaymentServices
  class ExPay
    class Payout < ::PaymentServices::Base::FiatPayout
      self.table_name = 'ex_pay_payouts'

      monetize :amount_cents, as: :amount

      private

      def provider_succeed?
        provider_state == Invoice::SUCCESS_PROVIDER_STATE
      end

      def provider_failed?
        provider_state == Invoice::FAILED_PROVIDER_STATE
      end
    end
  end
end
