# frozen_string_literal: true

module PaymentServices
  class Ff < Base
    autoload :Client, 'payment_services/ff/client'
    autoload :Invoice, 'payment_services/ff/invoice'
    autoload :Invoicer, 'payment_services/ff/invoicer'
    autoload :Payout, 'payment_services/ff/payout'
    autoload :PayoutAdapter, 'payment_services/ff/payout_adapter'
    autoload :Transaction, 'payment_services/ff/transaction'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
