# frozen_string_literal: true

class PaymentServices::Exmo
  class Payout < ApplicationRecord
    include Workflow

    self.table_name = 'exmo_payouts'

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

    def pay(task_id:)
      update(task_id: task_id)
    end

    def update_state_by_provider(state)
      update!(provider_state: state)

      confirm!  if success?
      fail!     if status_failed?
    end

    def order_fio
      order_payout.order.outcome_fio.presence || order_payout.order.outcome_unk
    end

    private

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end

    def success?
      provider_state == 'Paid'
    end

    def status_failed?
      provider_state == 'Cancelled' || provider_state == 'Error'
    end
  end
end
