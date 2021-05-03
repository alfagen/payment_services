# frozen_string_literal: true

class PaymentServices::Kuna
  class Invoice < ApplicationRecord
    FEE_PERCENT = 0.5

    include Workflow

    self.table_name = 'kuna_invoices'

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
          order.auto_confirm!(income_amount: amount)
        end
      end
      state :cancelled
    end

    def can_be_confirmed?(income_money:)
      pending? && amount_with_fee == income_money
    end

    def pay(payload:)
      update(payload: payload)
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    def amount_with_fee
      amount * (1 - FEE_PERCENT / 100)
    end
  end
end
