# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'client'

module PaymentServices
  class Rbk
    class WalletClient < PaymentServices::Rbk::Client
      URL = 'https://api.rbk.money/wallet/v0/wallets'

      def create_wallet(identity:)
        safely_parse http_request(
          url: URL,
          method: :POST,
          body: {
            name: 'Kassa.cc payouts wallet',
            identity: identity.rbk_id,
            currency: 'RUB'
          }
        )
      end
    end
  end
end
