# frozen_string_literal: true

module PaymentServices
  class Obmenka < Base
    autoload :Invoicer, 'payment_services/obmenka/invoicer'

    register :invoicer, Invoicer
  end
end
