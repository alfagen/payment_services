# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Rbk < Base
    CHECKOUT_URL = 'https://checkout.rbk.money/v1/checkout.html'

    # Используем autoload для всех классов
    autoload :Client, 'payment_services/rbk/client'
    autoload :Customer, 'payment_services/rbk/customer'
    autoload :CustomerClient, 'payment_services/rbk/customer_client'
    autoload :Identity, 'payment_services/rbk/identity'
    autoload :IdentityClient, 'payment_services/rbk/identity_client'
    autoload :Invoice, 'payment_services/rbk/invoice'
    autoload :InvoiceClient, 'payment_services/rbk/invoice_client'
    autoload :Invoicer, 'payment_services/rbk/invoicer'
    autoload :Payment, 'payment_services/rbk/payment'
    autoload :PaymentCard, 'payment_services/rbk/payment_card'
    autoload :PaymentClient, 'payment_services/rbk/payment_client'
    autoload :Payout, 'payment_services/rbk/payout'
    autoload :PayoutAdapter, 'payment_services/rbk/payout_adapter'
    autoload :PayoutClient, 'payment_services/rbk/payout_client'
    autoload :PayoutDestination, 'payment_services/rbk/payout_destination'
    autoload :PayoutDestinationClient, 'payment_services/rbk/payout_destination_client'
    autoload :Wallet, 'payment_services/rbk/wallet'
    autoload :WalletClient, 'payment_services/rbk/wallet_client'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
