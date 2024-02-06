# frozen_string_literal: true

module PaymentServices
  class Wallex < Base
    autoload :Invoicer, 'payment_services/wallex/invoicer'
    register :invoicer, Invoicer
  end
end
