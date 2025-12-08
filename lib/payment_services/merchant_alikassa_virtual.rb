# frozen_string_literal: true

module PaymentServices
  class MerchantAlikassaVirtual < Base
    autoload :Client, 'payment_services/merchant_alikassa_virtual/client'
    autoload :Invoice, 'payment_services/merchant_alikassa_virtual/invoice'
    autoload :Invoicer, 'payment_services/merchant_alikassa_virtual/invoicer'
    register :invoicer, Invoicer
  end
end
