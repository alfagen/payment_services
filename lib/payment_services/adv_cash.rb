# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class AdvCash < Base
    autoload :Client, 'payment_services/adv_cash/client'
    autoload :Invoice, 'payment_services/adv_cash/invoice'
    autoload :Invoicer, 'payment_services/adv_cash/invoicer'
    autoload :Payout, 'payment_services/adv_cash/payout'
    autoload :PayoutAdapter, 'payment_services/adv_cash/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
