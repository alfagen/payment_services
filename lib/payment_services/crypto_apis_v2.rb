# frozen_string_literal: true

module PaymentServices
  class CryptoApisV2 < Base
    autoload :Invoicer, 'payment_services/crypto_apis_v2/invoicer'
    autoload :PayoutAdapter, 'payment_services/crypto_apis_v2/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
