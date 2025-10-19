# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Rbk < Base
    CHECKOUT_URL = 'https://checkout.rbk.money/v1/checkout.html'

    # Используем autoload для всех классов
    autoload :Identity, 'payment_services/rbk/identity'
    autoload :Wallet, 'payment_services/rbk/wallet'
    autoload :PayoutDestination, 'payment_services/rbk/payout_destination'
    autoload :Payout, 'payment_services/rbk/payout'
    autoload :Payment, 'payment_services/rbk/payment'
    autoload :Invoice, 'payment_services/rbk/invoice'
    autoload :Customer, 'payment_services/rbk/customer'
    autoload :PaymentCard, 'payment_services/rbk/payment_card'
    autoload :PayoutAdapter, 'payment_services/rbk/payout_adapter'
    autoload :Invoicer, 'payment_services/rbk/invoicer'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
