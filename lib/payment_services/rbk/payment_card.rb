# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

class PaymentServices::Rbk
  class PaymentCard < PaymentServices::ApplicationRecord
    self.table_name = 'rbk_payment_cards'

    enum :card_type, %i[bank_card applepay googlepay], prefix: :card_type

    belongs_to :rbk_customer, class_name: 'PaymentServices::Rbk::Customer', foreign_key: :rbk_customer_id

    def masked_number
      # NOTE dup нужен, т.к. insert изменяет исходный объект
      return ' ** **** ' if bin.empty? && last_digits.empty?

      bin_with_space = bin.dup.insert(4, ' ')
      "#{bin_with_space}** **** #{last_digits}"
    end
  end
end
