# frozen_string_literal: true

module PaymentServices
  class PaylamaSbp < Base
    autoload :Client, 'payment_services/paylama_sbp/client'
    autoload :Invoice, 'payment_services/paylama_sbp/invoice'
    autoload :Invoicer, 'payment_services/paylama_sbp/invoicer'
    register :invoicer, Invoicer
  end
end
