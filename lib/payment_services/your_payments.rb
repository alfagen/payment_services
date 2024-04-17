# frozen_string_literal: true

module PaymentServices
  class YourPayments < Base
    autoload :Invoicer, 'payment_services/your_payments/invoicer'
    register :invoicer, Invoicer
  end
end
