# frozen_string_literal: true

module PaymentServices
  class CryptoApisV2 < Base
    autoload :Invoicer, 'payment_services/crypto_apis_v2/invoicer'
    register :invoicer, Invoicer
  end
end
