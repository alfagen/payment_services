# frozen_string_literal: true

module PaymentServices
  class Exmo < Base
    autoload :Invoicer, 'payment_services/exmo/invoicer'
    autoload :PayoutAdapter, 'payment_services/exmo/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
