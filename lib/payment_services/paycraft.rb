# frozen_string_literal: true

module PaymentServices
  class Paycraft < Base
    autoload :Invoicer, 'payment_services/paycraft/invoicer'
    register :invoicer, Invoicer
  end
end
