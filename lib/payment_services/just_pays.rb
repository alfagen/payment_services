# frozen_string_literal: true

module PaymentServices
  class JustPays < Base
    autoload :Client, 'payment_services/just_pays/client'
    autoload :Invoice, 'payment_services/just_pays/invoice'
    autoload :Invoicer, 'payment_services/just_pays/invoicer'
    register :invoicer, Invoicer
  end
end
