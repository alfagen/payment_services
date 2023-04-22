# frozen_string_literal: true

module PaymentServices
  class ExPay < Base
    autoload :Invoicer, 'payment_services/ex_pay/invoicer'
    autoload :PayoutAdapter, 'payment_services/ex_pay/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
