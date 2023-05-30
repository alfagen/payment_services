# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Rbk < Base
    CHECKOUT_URL = 'https://checkout.rbk.money/v1/checkout.html'
    autoload :PayoutAdapter, 'payment_services/rbk/payout_adapter'
    autoload :Invoicer, 'payment_services/rbk/invoicer'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
# FIXME: не знаю как проще подгрузить все файлы из rbk
require_relative 'rbk/identity'
require_relative 'rbk/wallet'
require_relative 'rbk/payout_destination'
require_relative 'rbk/payout'
