# frozen_string_literal: true

module PaymentServices
  class Bovapay < Base
    autoload :Invoicer, 'payment_services/bovapay/invoicer'
    autoload :PayoutAdapter, 'payment_services/bovapay/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
