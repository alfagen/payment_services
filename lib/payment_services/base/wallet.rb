# frozen_string_literal: true

class PaymentServices::Base
  class Wallet
    include Virtus.model

    attribute :address, String
    attribute :name, String
    attribute :memo, String

    def initialize(address:, name:, memo: nil)
      @address = address
      @name = name
      @memo = memo
    end
  end
end
