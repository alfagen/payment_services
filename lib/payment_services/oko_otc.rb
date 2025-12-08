# frozen_string_literal: true

module PaymentServices
  class OkoOtc < Base
    autoload :Client, 'payment_services/oko_otc/client'
    autoload :Payout, 'payment_services/oko_otc/payout'
    autoload :PayoutAdapter, 'payment_services/oko_otc/payout_adapter'
    register :payout_adapter, PayoutAdapter
  end
end
