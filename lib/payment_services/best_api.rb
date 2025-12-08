# frozen_string_literal: true

module PaymentServices
  class BestApi < Base
    autoload :Client, 'payment_services/best_api/client'
    autoload :Invoice, 'payment_services/best_api/invoice'
    autoload :Invoicer, 'payment_services/best_api/invoicer'
    register :invoicer, Invoicer
  end
end
