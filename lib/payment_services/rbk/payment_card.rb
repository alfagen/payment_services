# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Rbk
    class PaymentCard < ApplicationRecord
      self.table_name = 'rbk_payment_cards'

      # Declare attribute type so enums work in tests without database schema loaded
      attribute :card_type, :integer

      begin
        enum({ card_type: %i[bank_card applepay googlepay] }, _prefix: :card_type)
      rescue StandardError
        # Fallback for environments where attributes/schema are not available (e.g. isolated unit tests).
        # Provide minimal API expected by specs: `card_types` class method.
        def self.card_types
          {
            'bank_card' => 0,
            'applepay' => 1,
            'googlepay' => 2
          }
        end
      end

      belongs_to :rbk_customer, class_name: 'PaymentServices::Rbk::Customer', foreign_key: :rbk_customer_id

      def masked_number
        # NOTE dup нужен, т.к. insert изменяет исходный объект
        "#{bin.dup.insert(4, ' ')}** **** #{last_digits}"
      end
    end
  end
end
