# frozen_string_literal: true

module PaymentServices
  class Tronscan < Base
    autoload :Client, 'payment_services/tronscan/client'
    autoload :Invoice, 'payment_services/tronscan/invoice'
    autoload :Invoicer, 'payment_services/tronscan/invoicer'
    autoload :Transaction, 'payment_services/tronscan/transaction'
    autoload :TransactionMatcher, 'payment_services/tronscan/transaction_matcher'
    register :invoicer, Invoicer
  end
end
