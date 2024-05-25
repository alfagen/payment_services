# frozen_string_literal: true

module PaymentServices
  class Transfera < Base
    autoload :Invoicer, 'payment_services/transfera/invoicer'
    register :invoicer, Invoicer
  end
end
