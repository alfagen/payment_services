# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class Rbk
    class PaymentCard < ApplicationRecord
      self.table_name = 'rbk_payment_cards'

      enum :card_type, { bank_card: 0, applepay: 1, googlepay: 2 }, prefix: :card_type

      belongs_to :rbk_customer, class_name: 'PaymentServices::Rbk::Customer', foreign_key: :rbk_customer_id

      def masked_number
        # NOTE dup нужен, т.к. insert изменяет исходный объект
        bin_copy = bin.to_s.dup
        bin_formatted = bin_copy.length >= 4 ? bin_copy.insert(4, ' ') : "#{bin_copy} "
        "#{bin_formatted}** **** #{last_digits}"
      end
    end
  end
end
