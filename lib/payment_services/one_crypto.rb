# frozen_string_literal: true

module PaymentServices
  class OneCrypto < Base
    autoload :Invoicer, 'payment_services/one_crypto/invoicer'
    autoload :PayoutAdapter, 'payment_services/one_crypto/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
