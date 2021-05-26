# frozen_string_literal: true

class PaymentServices::Liquid
  class Payout < ApplicationRecord
    include Workflow
    self.table_name = 'liquid_payouts'

    SUCCESS_PAYOUT_STATE = 'processed'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :address, :state, presence: true

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

    def pay(withdrawal_id:)
      update(withdrawal_id: withdrawal_id)
    end

    def complete_payout?
      status == SUCCESS_PAYOUT_STATE
    end

    def txid
      transaction_id
    end
  end
end
