# frozen_string_literal: true

class PaymentServices::Base
  class CryptoInvoice < PaymentServices::ApplicationRecord
    include WorkflowActiverecord

    scope :ordered, -> { order(id: :desc) }

    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :bind_transaction, transitions_to: :with_transaction
      end
      state :with_transaction do
        on_entry do
          order.make_reserve!
        end
        event :pay, transitions_to: :paid
      end
      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount, hash: transaction_id)
        end
      end
      state :cancelled
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    def pay(payload:)
      update(payload: payload)
    end
  end
end
