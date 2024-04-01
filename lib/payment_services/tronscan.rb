# frozen_string_literal: true

module PaymentServices
  class Tronscan < Base
    autoload :Invoicer, 'payment_services/tronscan/invoicer'
    register :invoicer, Invoicer
  end
end
