# frozen_string_literal: true

module PaymentServices
  class MerchantAlikassa < Base
    autoload :Client, 'payment_services/merchant_alikassa/client'
    autoload :Invoice, 'payment_services/merchant_alikassa/invoice'
    autoload :Invoicer, 'payment_services/merchant_alikassa/invoicer'
    autoload :Payout, 'payment_services/merchant_alikassa/payout'
    autoload :PayoutAdapter, 'payment_services/merchant_alikassa/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
