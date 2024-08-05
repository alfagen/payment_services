# frozen_string_literal: true

module PaymentServices
  class Paycraft < Base
    autoload :Invoicer, 'payment_services/paycraft/invoicer'
    autoload :PayoutAdapter, 'payment_services/paycraft/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
