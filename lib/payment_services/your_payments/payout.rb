# frozen_string_literal: true

class PaymentServices::YourPayments
  class Payout < ::PaymentServices::Base::FiatPayout
    self.table_name = 'your_payments_payouts'

    monetize :amount_cents, as: :amount

    private

    def provider_succeed?
      provider_state.in? Invoice::SUCCESS_PROVIDER_STATES
    end

    def provider_failed?
      provider_state.in? Invoice::FAILED_PROVIDER_STATES
    end
  end
end
