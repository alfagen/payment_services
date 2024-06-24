# frozen_string_literal: true

module PaymentServices
  class Cryptomus < Base
    autoload :Invoicer, 'payment_services/cryptomus/invoicer'
    autoload :PayoutAdapter, 'payment_services/cryptomus/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
