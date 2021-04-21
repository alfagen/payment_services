# frozen_string_literal: true

class PaymentServices::Kuna
  class Payout < ApplicationRecord
    include Workflow

    self.table_name = 'kuna_payouts'

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

    def pay(withdrawal_id:)
      update(withdrawal_id: withdrawal_id)
    end

    def success?
      status == 'done'
    end

    def status_failed?
      status == 'canceled' || status == 'unknown'
    end
  end
end
