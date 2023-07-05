# frozen_string_literal: true

module PaymentServices
  class OneCrypto < Base
    autoload :Invoicer, 'payment_services/one_crypto/invoicer'
    register :invoicer, Invoicer
  end
end
