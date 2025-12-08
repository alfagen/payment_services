# frozen_string_literal: true

# Copyright (c) 2019 FINFEX https://github.com/finfex

require_relative 'wallet_client'

module PaymentServices
  class Rbk
    class Wallet < ApplicationRecord
      self.table_name = 'rbk_wallets'

      belongs_to :rbk_identity, class_name: 'PaymentServices::Rbk::Identity', foreign_key: :rbk_identity_id

      def self.create_for_identity(identity)
        response = WalletClient.new.create_wallet(identity: identity)
        identity.rbk_wallets.create!(
          rbk_id: response['id'],
          payload: response
        )
      end
    end
  end
end
