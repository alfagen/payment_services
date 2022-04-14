# frozen_string_literal: true

class PaymentServices::BlockIo
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 1
    include Workflow
    self.table_name = 'block_io_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :address, :fee, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
      end
      state :paid do
        event :confirm, transitions_to: :completed
      end
      state :completed
      state :failed
    end

    def pay(transaction_id:)
      update(transaction_id: transaction_id)
    end

    def confirmed?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end
  end
end
