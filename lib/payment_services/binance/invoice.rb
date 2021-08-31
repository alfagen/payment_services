# frozen_string_literal: true

class PaymentServices::Binance
  class Invoice < ApplicationRecord
    include Workflow

    self.table_name = 'binance_invoices'

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

    def update_state_by_provider(state)
      update!(provider_state: state)

      pay!    if success?
      cancel! if failed?
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    def success?
      provider_state == 1
    end

    def failed?
      provider_state == 6
    end
  end
end
