# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

module PaymentServices
  class CryptoApis < Base
    autoload :Invoicer, 'payment_services/crypto_apis/invoicer'
    autoload :PayoutAdapter, 'payment_services/crypto_apis/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
