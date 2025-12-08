# frozen_string_literal: true

module PaymentServices
  class CryptoApisV2 < Base
    autoload :Blockchain, 'payment_services/crypto_apis_v2/blockchain'
    autoload :Client, 'payment_services/crypto_apis_v2/client'
    autoload :Invoice, 'payment_services/crypto_apis_v2/invoice'
    autoload :Invoicer, 'payment_services/crypto_apis_v2/invoicer'
    autoload :Payout, 'payment_services/crypto_apis_v2/payout'
    autoload :PayoutAdapter, 'payment_services/crypto_apis_v2/payout_adapter'
    autoload :Transaction, 'payment_services/crypto_apis_v2/transaction'
    autoload :TransactionRepository, 'payment_services/crypto_apis_v2/transaction_repository'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter

    def self.payout_contains_fee?
      true
    end
  end
end
