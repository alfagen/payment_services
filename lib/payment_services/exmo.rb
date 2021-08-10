# frozen_string_literal: true

module PaymentServices
  class Exmo < Base
    autoload :PayoutAdapter, 'payment_services/exmo/payout_adapter'
    register :payout_adapter, PayoutAdapter
  end
end
