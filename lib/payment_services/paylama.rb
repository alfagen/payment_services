# frozen_string_literal: true

module PaymentServices
  class Paylama < Base
    autoload :Client, 'payment_services/paylama/client'
    autoload :CurrencyRepository, 'payment_services/paylama/currency_repository'
    autoload :Invoice, 'payment_services/paylama/invoice'
    autoload :Invoicer, 'payment_services/paylama/invoicer'
    autoload :Payout, 'payment_services/paylama/payout'
    autoload :PayoutAdapter, 'payment_services/paylama/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
