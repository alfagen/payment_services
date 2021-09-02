# frozen_string_literal: true

module PaymentServices
  class Binance < Base
    autoload :Invoicer, 'payment_services/binance/invoicer'
    autoload :PayoutAdapter, 'payment_services/binance/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
