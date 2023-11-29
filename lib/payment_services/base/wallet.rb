# frozen_string_literal: true

class PaymentServices::Base
  class Wallet
    include Virtus.model

    attribute :address, String
    attribute :name, String
    attribute :memo, String
    attribute :name_group, String

    def initialize(address:, name:, memo: nil, name_group: nil)
      @address = address
      @name = name
      @memo = memo
      @name_group = name_group
    end
  end
end
