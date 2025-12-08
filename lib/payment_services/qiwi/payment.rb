# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

# Выдержка из внешнего журнала транзакций
#
# TODO А чем она отличается от выдержек из других ПС?

require_relative 'payment_order_support'

module PaymentServices
  class QIWI
    class Payment < ApplicationRecord
      include AutoLogger
      extend Enumerize
      include PaymentOrderSupport

      self.table_name = :qiwi_payments

      has_many :income_links, as: :external_payment

      scope :ordered, -> { order 'id desc, date desc' }
      monetize :total_cents, as: :total

      enum status: %i[UNKNOWN WAITING SUCCESS ERROR]
      enumerize :direction_type, in: %w[IN OUT], predicates: { prefix: true }

      def success_in?
        SUCCESS? && direction_type_IN?
      end
    end
  end
end
