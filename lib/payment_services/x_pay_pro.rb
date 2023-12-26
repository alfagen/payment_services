# frozen_string_literal: true

module PaymentServices
  class XPayPro < Base
    autoload :Invoicer, 'payment_services/x_pay_pro/invoicer'
    register :invoicer, Invoicer
  end
end
