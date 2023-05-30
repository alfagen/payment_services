# frozen_string_literal: true

# Copyright (c) 2019 FINFEX https://github.com/finfex

require_relative 'identity_client'

class PaymentServices::Rbk
  class Identity < ApplicationRecord
    self.table_name = 'rbk_identities'

    has_many :rbk_wallets,
             class_name: 'PaymentServices::Rbk::Wallet',
             foreign_key: :rbk_identity_id
    has_many :rbk_payout_destinations,
             class_name: 'PaymentServices::Rbk::PayoutDestination',
             foreign_key: :rbk_identity_id

    def self.current
      find_by(current: true)
    end

    def self.create_sample!
      response = IdentityClient.new.create_sample_identity
      create!(
        rbk_id: response['id'],
        payload: response
      )
    end

    def current_wallet
      rbk_wallets.find_by(current: true)
    end
  end
end
