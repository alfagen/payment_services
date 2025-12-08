# frozen_string_literal: true

module PaymentServices
  class CoinPaymentsHub < Base
    autoload :Client, 'payment_services/coin_payments_hub/client'
    autoload :CurrencyRepository, 'payment_services/coin_payments_hub/currency_repository'
    autoload :Invoice, 'payment_services/coin_payments_hub/invoice'
    autoload :Invoicer, 'payment_services/coin_payments_hub/invoicer'
    autoload :Transaction, 'payment_services/coin_payments_hub/transaction'
    register :invoicer, Invoicer
  end
end
