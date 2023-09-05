# frozen_string_literal: true

module PaymentServices
  class PayForU < Base
    autoload :Invoicer, 'payment_services/pay_for_u/invoicer'
    register :invoicer, Invoicer
  end
end
