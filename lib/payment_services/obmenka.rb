# frozen_string_literal: true

module PaymentServices
  class Obmenka < Base
    autoload :Invoicer, 'payment_services/obmenka/invoicer'
    autoload :PayoutAdapter, 'payment_services/obmenka/payout_adapter'
    register :payout_adapter, PayoutAdapter
    register :invoicer, Invoicer
  end
end
