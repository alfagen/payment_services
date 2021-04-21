# frozen_string_literal: true

module PaymentServices
  class Kuna < Base
    # autoload :Invoicer, 'payment_services/kuna/invoicer'
    autoload :PayoutAdapter, 'payment_services/kuna/payout_adapter'
    # register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
