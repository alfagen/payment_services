# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Wallet < ApplicationRecord
    self.table_name = 'crypto_apis_wallets'

    validates :address, :wif, :api_key, :currency, presence: true

    has_many :payouts
  end
end
