# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

module PaymentServices
  class CryptoApis < Base
    autoload :Invoicer, 'payment_services/crypto_apis/invoicer'
    autoload :PayoutClient, 'payment_services/crypto_apis/payout_client'
    register :invoicer, Invoicer
    register :payout_client, PayoutClient
  end
end
