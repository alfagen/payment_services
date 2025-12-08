# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class PerfectMoney < Base
    autoload :Client, 'payment_services/perfect_money/client'
    autoload :Invoice, 'payment_services/perfect_money/invoice'
    autoload :Invoicer, 'payment_services/perfect_money/invoicer'
    autoload :Payout, 'payment_services/perfect_money/payout'
    autoload :PayoutAdapter, 'payment_services/perfect_money/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
