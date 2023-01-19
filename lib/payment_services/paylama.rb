# frozen_string_literal: true

module PaymentServices
  class Paylama < Base
    autoload :Invoicer, 'payment_services/paylama/invoicer'
    autoload :PayoutAdapter, 'payment_services/paylama/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
