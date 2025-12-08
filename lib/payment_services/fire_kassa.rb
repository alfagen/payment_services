# frozen_string_literal: true

module PaymentServices
  class FireKassa < Base
    autoload :Client, 'payment_services/fire_kassa/client'
    autoload :Invoice, 'payment_services/fire_kassa/invoice'
    autoload :Invoicer, 'payment_services/fire_kassa/invoicer'
    register :invoicer, Invoicer
  end
end
