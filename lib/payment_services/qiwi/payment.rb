# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

# Выдержка из внешнего журнала транзакций
#
# TODO А чем она отличается от выдержек из других ПС?

require_relative 'payment_order_support'

class PaymentServices::QIWI
  class Payment < ApplicationRecord
    include AutoLogger
    include PaymentOrderSupport

    self.table_name = :qiwi_payments

    has_many :income_links, as: :external_payment

    scope :ordered, -> { order 'id desc, date desc' }
    monetize :total_cents, as: :total

    enum :status, %i[UNKNOWN WAITING SUCCESS ERROR]
    enum :direction_type, { in: 'IN', out: 'OUT' }

    def success_in?
      SUCCESS? && in?
    end
  end
end
