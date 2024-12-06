# frozen_string_literal: true

module PaymentServices
  class PayFinity < Base
    autoload :Invoicer, 'payment_services/pay_finity/invoicer'
    register :invoicer, Invoicer
  end
end
