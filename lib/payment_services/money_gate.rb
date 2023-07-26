# frozen_string_literal: true

module PaymentServices
  class MoneyGate < Base
    autoload :Invoicer, 'payment_services/money_gate/invoicer'
    register :invoicer, Invoicer
  end
end
