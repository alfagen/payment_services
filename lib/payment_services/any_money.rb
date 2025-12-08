# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class AnyMoney < Base
    autoload :Client, 'payment_services/any_money/client'
    autoload :Invoice, 'payment_services/any_money/invoice'
    autoload :Invoicer, 'payment_services/any_money/invoicer'
    autoload :Payout, 'payment_services/any_money/payout'
    autoload :PayoutAdapter, 'payment_services/any_money/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
