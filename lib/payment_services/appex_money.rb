# frozen_string_literal: true

module PaymentServices
  class AppexMoney < Base
    autoload :PayoutAdapter, 'payment_services/appex_money/payout_adapter'
    register :payout_adapter, PayoutAdapter
  end
end
