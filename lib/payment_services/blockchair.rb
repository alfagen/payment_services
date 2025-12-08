# frozen_string_literal: true

module PaymentServices
  class Blockchair < Base
    autoload :Blockchain, 'payment_services/blockchair/blockchain'
    autoload :Client, 'payment_services/blockchair/client'
    autoload :Invoice, 'payment_services/blockchair/invoice'
    autoload :Invoicer, 'payment_services/blockchair/invoicer'
    autoload :Transaction, 'payment_services/blockchair/transaction'
    autoload :TransactionMatcher, 'payment_services/blockchair/transaction_matcher'
    register :invoicer, Invoicer
  end
end
