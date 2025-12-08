# frozen_string_literal: true

module PaymentServices
  class XPayPro < Base
    autoload :Client, 'payment_services/x_pay_pro/client'
    autoload :Invoice, 'payment_services/x_pay_pro/invoice'
    autoload :Invoicer, 'payment_services/x_pay_pro/invoicer'
    register :invoicer, Invoicer
  end
end
