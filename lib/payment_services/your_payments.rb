# frozen_string_literal: true

module PaymentServices
  class YourPayments < Base
    autoload :Invoicer, 'payment_services/your_payments/invoicer'
    autoload :PayoutAdapter, 'payment_services/your_payments/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
