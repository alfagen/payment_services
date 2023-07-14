# frozen_string_literal: true

class PaymentServices::Base
  class CryptoPayout < ActiveRecord::Base
    include Workflow

    scope :ordered, -> { order(id: :desc) }

    validates :amount_cents, :destination_account, :state, :order_payout_id, presence: true

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

    def update_state_by_provider!(transaction)
      update!(
        provider_state: transaction.status,
        fee: transaction.fee
      )

      confirm! if transaction.succeed?
      fail! if transaction.failed?
    end
  end
end
