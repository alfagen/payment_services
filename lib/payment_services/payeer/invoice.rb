# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

class PaymentServices::Payeer
  class Invoice < ApplicationRecord
    include Workflow
    self.table_name = 'payeer_invoices'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount

    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          preliminary_order&.auto_confirm!(income_amount: amount)
        end
      end
      state :cancelled
    end

    def can_be_confirmed?(income_money:)
      pending? && amount == income_money
    end

    def pay(payload:)
      update(payload: payload)
    end

    def order
      Order.find_by(public_id: order_public_id)
    end

    private

    def preliminary_order
      PreliminaryOrder.find_by(public_id: order_public_id)
    end
  end
end
