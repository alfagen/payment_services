# frozen_string_literal: true

module PaymentServices
  class Bridgex < Base
    autoload :Client, 'payment_services/bridgex/client'
    autoload :Invoice, 'payment_services/bridgex/invoice'
    autoload :Invoicer, 'payment_services/bridgex/invoicer'
    register :invoicer, Invoicer
  end
end
