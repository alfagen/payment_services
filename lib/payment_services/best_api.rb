# frozen_string_literal: true

module PaymentServices
  class BestApi < Base
    autoload :Invoicer, 'payment_services/best_api/invoicer'
    register :invoicer, Invoicer
  end
end
