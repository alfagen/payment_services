# frozen_string_literal: true

module PaymentServices
  class MerchantAlikassa < Base
    autoload :Invoicer, 'payment_services/merchant_alikassa/invoicer'
    autoload :PayoutAdapter, 'payment_services/merchant_alikassa/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
