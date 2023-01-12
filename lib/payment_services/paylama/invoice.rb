# frozen_string_literal: true

class PaymentServices::Paylama
  class Invoice < ApplicationRecord
    include Workflow

    self.table_name = 'paylama_invoices'

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

    def pay(payload:)
      update(payload: payload)
    end
  end
end
