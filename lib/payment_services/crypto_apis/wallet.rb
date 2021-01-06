# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Wallet < ApplicationRecord
    include Workflow
    self.table_name = 'crypto_apis_wallets'

    validates :address, :balance, :wif, presence: true

    has_many :payout_payments
    has_many :payouts, through: :payout_payments
  end
end
