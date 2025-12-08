# frozen_string_literal: true

module PaymentServices
  class PaylamaCrypto < Base
    autoload :Invoice, 'payment_services/paylama_crypto/invoice'
    autoload :Invoicer, 'payment_services/paylama_crypto/invoicer'
    autoload :Payout, 'payment_services/paylama_crypto/payout'
    autoload :PayoutAdapter, 'payment_services/paylama_crypto/payout_adapter'
    autoload :Transaction, 'payment_services/paylama_crypto/transaction'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter

    def self.payout_contains_fee?
      true
    end
  end
end
