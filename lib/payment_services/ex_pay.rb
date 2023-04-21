# frozen_string_literal: true

module PaymentServices
  class ExPay < Base
    autoload :Invoicer, 'payment_services/ex_pay/invoicer'
    register :invoicer, Invoicer
  end
end
