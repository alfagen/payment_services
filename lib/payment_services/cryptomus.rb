# frozen_string_literal: true

module PaymentServices
  class Cryptomus < Base
    autoload :Invoicer, 'payment_services/cryptomus/invoicer'
    register :invoicer, Invoicer
  end
end
