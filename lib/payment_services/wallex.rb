# frozen_string_literal: true

module PaymentServices
  class Wallex < Base
    autoload :Client, 'payment_services/wallex/client'
    autoload :Invoice, 'payment_services/wallex/invoice'
    autoload :Invoicer, 'payment_services/wallex/invoicer'
    autoload :Payout, 'payment_services/wallex/payout'
    autoload :PayoutAdapter, 'payment_services/wallex/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
