# frozen_string_literal: true

module PaymentServices
  class AnyPay < Base
    autoload :Client, 'payment_services/any_pay/client'
    autoload :Invoice, 'payment_services/any_pay/invoice'
    autoload :Invoicer, 'payment_services/any_pay/invoicer'
    autoload :Payout, 'payment_services/any_pay/payout'
    autoload :PayoutAdapter, 'payment_services/any_pay/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
