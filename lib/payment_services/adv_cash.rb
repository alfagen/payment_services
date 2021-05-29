# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class AdvCash < Base
    autoload :Invoicer, 'payment_services/adv_cash/invoicer'
    autoload :PayoutAdapter, 'payment_services/adv_cash/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
