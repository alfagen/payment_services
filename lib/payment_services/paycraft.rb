# frozen_string_literal: true

module PaymentServices
  class Paycraft < Base
    autoload :Client, 'payment_services/paycraft/client'
    autoload :Invoice, 'payment_services/paycraft/invoice'
    autoload :Invoicer, 'payment_services/paycraft/invoicer'
    autoload :Payout, 'payment_services/paycraft/payout'
    autoload :PayoutAdapter, 'payment_services/paycraft/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
