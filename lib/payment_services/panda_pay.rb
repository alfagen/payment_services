# frozen_string_literal: true

module PaymentServices
  class PandaPay < Base
    autoload :Client, 'payment_services/panda_pay/client'
    autoload :Invoice, 'payment_services/panda_pay/invoice'
    autoload :Invoicer, 'payment_services/panda_pay/invoicer'
    register :invoicer, Invoicer
  end
end
