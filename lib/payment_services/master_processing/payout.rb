# frozen_string_literal: true

class PaymentServices::MasterProcessing
  class Payout < PaymentServices::ApplicationRecord
    include WorkflowActiverecord

    self.table_name = 'master_processing_payouts'

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
      provider_state == 'success'
    end

    def status_failed?
      provider_state == 'canceled' || provider_state == 'failed'
    end
  end
end
