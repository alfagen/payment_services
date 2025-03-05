# frozen_string_literal: true

module PaymentServices
  class Capitalist < Base
    autoload :PayoutAdapter, 'payment_services/capitalist/payout_adapter'
    register :payout_adapter, PayoutAdapter
  end
end
