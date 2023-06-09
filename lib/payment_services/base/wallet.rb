# frozen_string_literal: true

class PaymentServices::Base
  class Wallet
    include Virtus.model

    attribute :address, String
    attribute :name, String

    def initialize(address:, name:)
      @address = address
      @name = name
    end
  end
end
