# frozen_string_literal: true

module PaymentServices
  class Ff < Base
    autoload :Invoicer, 'payment_services/ff/invoicer'
    autoload :PayoutAdapter, 'payment_services/ff/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
