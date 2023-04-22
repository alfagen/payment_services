# frozen_string_literal: true

class PaymentServices::Base
  class FiatPayout < ActiveRecord::Base
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

    def update_state_by_provider(state)
      update!(provider_state: state)

      confirm! if provider_succeed?
      fail! if provider_failed?
    end

    private

    def provider_succeed?
      raise "Method `provider_succeed?` is not implemented for class #{self.class}"
    end

    def provider_failed?
      raise "Method `provider_failed?` is not implemented for class #{self.class}"
    end
  end
end
