# frozen_string_literal: true

module PaymentServices
  class AppexMoney < Base
    autoload :Client, 'payment_services/appex_money/client'
    autoload :Payout, 'payment_services/appex_money/payout'
    autoload :PayoutAdapter, 'payment_services/appex_money/payout_adapter'
    register :payout_adapter, PayoutAdapter
  end
end
