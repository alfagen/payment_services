# frozen_string_literal: true

module PaymentServices
  class PaycraftVirtual < Base
    autoload :Client, 'payment_services/paycraft_virtual/client'
    autoload :Invoice, 'payment_services/paycraft_virtual/invoice'
    autoload :Invoicer, 'payment_services/paycraft_virtual/invoicer'

    register :invoicer, Invoicer
  end
end
