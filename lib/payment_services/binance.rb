# frozen_string_literal: true

module PaymentServices
  class Binance < Base
    autoload :Invoicer, 'payment_services/binance/invoicer'
    register :invoicer, Invoicer
  end
end
