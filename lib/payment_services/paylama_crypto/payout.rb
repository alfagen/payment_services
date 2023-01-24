# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Payout < ApplicationRecord
    SUCCESS_PROVIDER_STATE  = 'Succeed'
    FAILED_PROVIDER_STATE   = 'Failed'

    include Workflow

    self.table_name = 'paylama_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
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

    def update_state_by_provider(state)
      update!(provider_state: state)

      confirm! if provider_succeed?
      fail! if provider_failed?
    end

    private

    def provider_succeed?
      provider_state == SUCCESS_PROVIDER_STATE
    end

    def provider_failed?
      provider_state == FAILED_PROVIDER_STATE
    end
  end
end
