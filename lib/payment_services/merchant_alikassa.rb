# frozen_string_literal: true

module PaymentServices
  class MerchantAlikassa < Base
    autoload :Invoicer, 'payment_services/merchant_alikassa/invoicer'
    register :invoicer, Invoicer
  end
end
