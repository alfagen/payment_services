# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

module PaymentServices
  class CryptoApis < Base
    autoload :Client, 'payment_services/crypto_apis/client'
    autoload :Invoice, 'payment_services/crypto_apis/invoice'
    autoload :Invoicer, 'payment_services/crypto_apis/invoicer'
    autoload :Payout, 'payment_services/crypto_apis/payout'
    autoload :PayoutAdapter, 'payment_services/crypto_apis/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
