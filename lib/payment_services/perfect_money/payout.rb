# frozen_string_literal: true

class PaymentServices::PerfectMoney
  class Payout < ApplicationRecord
    include WorkflowActiverecord

    self.table_name = 'perfect_money_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :destination_account, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
      end
      state :paid do
        event :confirm, transitions_to: :completed
        event :fail, transitions_to: :failed
      end
      state :completed
      state :failed
    end

    def pay(payment_batch_number:)
      update(payment_batch_number: payment_batch_number)
    end

    def build_payment_id
      "#{order_payout.order.public_id}-#{order_payout.id}"
    end

    private

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end
  end
end
