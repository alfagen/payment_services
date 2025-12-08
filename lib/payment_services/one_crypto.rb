# frozen_string_literal: true

module PaymentServices
  class OneCrypto < Base
    autoload :Client, 'payment_services/one_crypto/client'
    autoload :Invoice, 'payment_services/one_crypto/invoice'
    autoload :Invoicer, 'payment_services/one_crypto/invoicer'
    autoload :Payout, 'payment_services/one_crypto/payout'
    autoload :PayoutAdapter, 'payment_services/one_crypto/payout_adapter'
    autoload :Transaction, 'payment_services/one_crypto/transaction'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
