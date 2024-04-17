# frozen_string_literal: true

module PaymentServices
  class YourPayments < Base
    autoload :Invoicer, 'payment_services/your_payments/invoicer'
<<<<<<< HEAD
    autoload :PayoutAdapter, 'payment_services/your_payments/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
=======
    register :invoicer, Invoicer
>>>>>>> master
  end
end
