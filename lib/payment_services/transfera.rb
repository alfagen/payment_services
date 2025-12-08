# frozen_string_literal: true

module PaymentServices
  class Transfera < Base
    autoload :Client, 'payment_services/transfera/client'
    autoload :Invoice, 'payment_services/transfera/invoice'
    autoload :Invoicer, 'payment_services/transfera/invoicer'
    register :invoicer, Invoicer
  end
end
