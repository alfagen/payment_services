# frozen_string_literal: true

module PaymentServices
  class Liquid < Base
    autoload :Client, 'payment_services/liquid/client'
    autoload :Invoice, 'payment_services/liquid/invoice'
    autoload :Invoicer, 'payment_services/liquid/invoicer'
    autoload :Payout, 'payment_services/liquid/payout'
    autoload :PayoutAdapter, 'payment_services/liquid/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
