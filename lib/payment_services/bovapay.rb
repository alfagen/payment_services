# frozen_string_literal: true

module PaymentServices
  class Bovapay < Base
    autoload :Client, 'payment_services/bovapay/client'
    autoload :Invoice, 'payment_services/bovapay/invoice'
    autoload :Invoicer, 'payment_services/bovapay/invoicer'
    autoload :Payout, 'payment_services/bovapay/payout'
    autoload :PayoutAdapter, 'payment_services/bovapay/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
