# frozen_string_literal: true

module PaymentServices
  class XPayProVirtual < Base
    autoload :Invoicer, 'payment_services/x_pay_pro_virtual/invoicer'
    register :invoicer, Invoicer
  end
end
