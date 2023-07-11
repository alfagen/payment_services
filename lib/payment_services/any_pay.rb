# frozen_string_literal: true

module PaymentServices
  class AnyPay < Base
    autoload :Invoicer, 'payment_services/any_pay/invoicer'
    autoload :PayoutAdapter, 'payment_services/any_pay/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
