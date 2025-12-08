# frozen_string_literal: true

module PaymentServices
  class PaylamaP2p < Base
    autoload :Client, 'payment_services/paylama_p2p/client'
    autoload :Invoice, 'payment_services/paylama_p2p/invoice'
    autoload :Invoicer, 'payment_services/paylama_p2p/invoicer'
    register :invoicer, Invoicer
  end
end
