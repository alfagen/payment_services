# frozen_string_literal: true

class PaymentServices::Liquid
  class Invoice < ApplicationRecord
    include WorkflowActiverecord
    self.table_name = 'liquid_invoices'

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
          order.auto_confirm!(income_amount: amount, hash: transaction_id)
        end
      end
      state :cancelled
    end

    def complete_payment?
      provider_state == 'confirmed'
    end

    def pay(payload:)
      update(payload: payload)
    end

    def order
      @order ||= Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end
  end
end
