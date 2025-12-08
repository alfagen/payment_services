# frozen_string_literal: true

module PaymentServices
  class Erapay < Base
    autoload :Client, 'payment_services/erapay/client'
    autoload :Invoice, 'payment_services/erapay/invoice'
    autoload :Invoicer, 'payment_services/erapay/invoicer'
    register :invoicer, Invoicer
  end
end
