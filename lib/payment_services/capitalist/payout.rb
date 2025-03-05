# frozen_string_literal: true

class PaymentServices::Capitalist
  class Payout < ::PaymentServices::Base::FiatPayout
    SUCCESS_PROVIDER_STATE = 'PROCESSED'
    FAILED_PROVIDER_STATE  = 'DECLINED'

    self.table_name = 'capitalist_payouts'

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
