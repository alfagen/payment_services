# frozen_string_literal: true

module PaymentServices
  class Bridgex < Base
    autoload :Invoicer, 'payment_services/bridgex/invoicer'
    register :invoicer, Invoicer
  end
end
