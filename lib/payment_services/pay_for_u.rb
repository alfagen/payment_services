# frozen_string_literal: true

module PaymentServices
  class PayForU < Base
    autoload :Client, 'payment_services/pay_for_u/client'
    autoload :Invoice, 'payment_services/pay_for_u/invoice'
    autoload :Invoicer, 'payment_services/pay_for_u/invoicer'
    register :invoicer, Invoicer
  end
end
