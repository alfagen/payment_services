# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Payeer < Base
    autoload :Client, 'payment_services/payeer/client'
    autoload :Invoice, 'payment_services/payeer/invoice'
    autoload :Invoicer, 'payment_services/payeer/invoicer'
    autoload :Payout, 'payment_services/payeer/payout'
    autoload :PayoutAdapter, 'payment_services/payeer/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
