# frozen_string_literal: true

module PaymentServices
  class PayForUH2h < Base
    autoload :Client, 'payment_services/pay_for_u_h2h/client'
    autoload :Invoice, 'payment_services/pay_for_u_h2h/invoice'
    autoload :Invoicer, 'payment_services/pay_for_u_h2h/invoicer'
    register :invoicer, Invoicer
  end
end
