# frozen_string_literal: true

module PaymentServices
  class Cryptomus < Base
    autoload :Client, 'payment_services/cryptomus/client'
    autoload :Invoice, 'payment_services/cryptomus/invoice'
    autoload :Invoicer, 'payment_services/cryptomus/invoicer'
    autoload :Payout, 'payment_services/cryptomus/payout'
    autoload :PayoutAdapter, 'payment_services/cryptomus/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
