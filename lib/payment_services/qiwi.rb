# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class QIWI < Base
    autoload :Client, 'payment_services/qiwi/client'
    autoload :Importer, 'payment_services/qiwi/importer'
    autoload :Invoice, 'payment_services/qiwi/invoice'
    autoload :Invoicer, 'payment_services/qiwi/invoicer'
    autoload :Payment, 'payment_services/qiwi/payment'
    autoload :PaymentOrderSupport, 'payment_services/qiwi/payment_order_support'
    autoload :PayoutAdapter, 'payment_services/qiwi/payout_adapter'

    register :payout_adapter, PayoutAdapter
    register :importer, Importer
    register :invoicer, Invoicer
  end
end
