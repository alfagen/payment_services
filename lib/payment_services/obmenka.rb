# frozen_string_literal: true

module PaymentServices
  class Obmenka < Base
    autoload :Client, 'payment_services/obmenka/client'
    autoload :Invoice, 'payment_services/obmenka/invoice'
    autoload :Invoicer, 'payment_services/obmenka/invoicer'
    autoload :Payout, 'payment_services/obmenka/payout'
    autoload :PayoutAdapter, 'payment_services/obmenka/payout_adapter'
    register :payout_adapter, PayoutAdapter
    register :invoicer, Invoicer
  end
end
