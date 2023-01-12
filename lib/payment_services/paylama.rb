# frozen_string_literal: true

module PaymentServices
  class Paylama < Base
    autoload :Invoicer, 'payment_services/paylama/invoicer'
    register :invoicer, Invoicer
  end
end
