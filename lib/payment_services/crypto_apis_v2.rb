# frozen_string_literal: true

module PaymentServices
  class CryptoApisV2 < Base
    autoload :Invoicer, 'payment_services/crypto_apis/invoicer'
    register :invoicer, Invoicer
  end
end
