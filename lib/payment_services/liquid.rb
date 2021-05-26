# frozen_string_literal: true

module PaymentServices
  class Liquid < Base
    autoload :Invoicer, 'payment_services/liquid/invoicer'
    autoload :PayoutAdapter, 'payment_services/liquid/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
