# frozen_string_literal: true

module PaymentServices
  class MerchantAlikassaVirtual < Base
    autoload :Invoicer, 'payment_services/merchant_alikassa_virtual/invoicer'
    register :invoicer, Invoicer
  end
end
