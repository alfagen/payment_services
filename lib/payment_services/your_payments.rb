# frozen_string_literal: true

module PaymentServices
  class YourPayments < Base
    autoload :Client, 'payment_services/your_payments/client'
    autoload :Invoice, 'payment_services/your_payments/invoice'
    autoload :Invoicer, 'payment_services/your_payments/invoicer'
    autoload :Payout, 'payment_services/your_payments/payout'
    autoload :PayoutAdapter, 'payment_services/your_payments/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
