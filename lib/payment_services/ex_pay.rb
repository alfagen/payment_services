# frozen_string_literal: true

module PaymentServices
  class ExPay < Base
    autoload :Client, 'payment_services/ex_pay/client'
    autoload :Invoice, 'payment_services/ex_pay/invoice'
    autoload :Invoicer, 'payment_services/ex_pay/invoicer'
    autoload :Payout, 'payment_services/ex_pay/payout'
    autoload :PayoutAdapter, 'payment_services/ex_pay/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
