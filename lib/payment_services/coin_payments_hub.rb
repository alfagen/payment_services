# frozen_string_literal: true

module PaymentServices
  class CoinPaymentsHub < Base
    autoload :Invoicer, 'payment_services/coin_payments_hub/invoicer'
    register :invoicer, Invoicer
  end
end
