# frozen_string_literal: true

module PaymentServices
  class Wallex < Base
    autoload :Invoicer, 'payment_services/wallex/invoicer'
    autoload :PayoutAdapter, 'payment_services/wallex/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
