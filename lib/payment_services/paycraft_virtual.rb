# frozen_string_literal: true

module PaymentServices
  class PaycraftVirtual < Base
    autoload :Invoicer, 'payment_services/paycraft_virtual/invoicer'

    register :invoicer, Invoicer
  end
end
