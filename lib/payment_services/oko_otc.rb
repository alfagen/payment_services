# frozen_string_literal: true

module PaymentServices
  class OkoOtc < Base
    autoload :PayoutAdapter, 'payment_services/oko_otc/payout_adapter'
    register :payout_adapter, PayoutAdapter
  end
end
