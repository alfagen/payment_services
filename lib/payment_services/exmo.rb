# frozen_string_literal: true

module PaymentServices
  class Exmo < Base
    autoload :Client, 'payment_services/exmo/client'
    autoload :Invoice, 'payment_services/exmo/invoice'
    autoload :Invoicer, 'payment_services/exmo/invoicer'
    autoload :Payout, 'payment_services/exmo/payout'
    autoload :PayoutAdapter, 'payment_services/exmo/payout_adapter'
    autoload :Transaction, 'payment_services/exmo/transaction'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
