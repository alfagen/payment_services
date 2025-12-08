# frozen_string_literal: true

module PaymentServices
  class Kuna < Base
    autoload :Client, 'payment_services/kuna/client'
    autoload :Invoice, 'payment_services/kuna/invoice'
    autoload :Invoicer, 'payment_services/kuna/invoicer'
    autoload :Payout, 'payment_services/kuna/payout'
    autoload :PayoutAdapter, 'payment_services/kuna/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
