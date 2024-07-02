# frozen_string_literal: true

module PaymentServices
  class Bovapay < Base
    autoload :Invoicer, 'payment_services/bovapay/invoicer'
    register :invoicer, Invoicer
  end
end
