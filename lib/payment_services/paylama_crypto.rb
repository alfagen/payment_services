# frozen_string_literal: true

module PaymentServices
  class PaylamaCrypto < Base
    autoload :Invoicer, 'payment_services/paylama_crypto/invoicer'
    autoload :PayoutAdapter, 'payment_services/paylama_crypto/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
