# frozen_string_literal: true

module PaymentServices
  class Binance < Base
    autoload :Client, 'payment_services/binance/client'
    autoload :Invoice, 'payment_services/binance/invoice'
    autoload :Invoicer, 'payment_services/binance/invoicer'
    autoload :Payout, 'payment_services/binance/payout'
    autoload :PayoutAdapter, 'payment_services/binance/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
