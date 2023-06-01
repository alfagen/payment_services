# frozen_string_literal: true

class PaymentServices::Base
  class Wallet
    include Virtus.model

    attribute :address, String
    attribute :name, String

    def self.build_from(address:, name:)
      new(
        address: address,
        name: name
      )
    end
  end
end
