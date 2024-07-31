# frozen_string_literal: true

module PaymentServices
  class Erapay < Base
    autoload :Invoicer, 'payment_services/erapay/invoicer'
    register :invoicer, Invoicer
  end
end
