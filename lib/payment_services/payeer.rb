# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Payeer < Base
    autoload :Invoicer, 'payment_services/payeer/invoicer'
    autoload :PayoutAdapter, 'payment_services/payeer/payout_adapter'

    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
