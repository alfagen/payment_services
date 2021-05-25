# frozen_string_literal: true

class PaymentServices::Payeer
  class Payout < ApplicationRecord
    include Workflow

    self.table_name = 'payeer_payouts'

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

    def pay(reference_id:)
      update(reference_id: reference_id)
    end

    def success?
      provider_state == 'success'
    end

    def failed?
      provider_state == 'canceled'
    end
  end
end
