# frozen_string_literal: true

module PaymentServices
  class Liquid < Base
    autoload :Invoicer, 'payment_services/liquid/invoicer'
    register :invoicer, Invoicer
  end
end
