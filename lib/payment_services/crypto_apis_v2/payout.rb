# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Payout < ApplicationRecord
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    PAYOUT_SUCCESS_PROVIDER_STATE = 'success'
    PAYOUT_FAILED_PROVIDER_STATES = %w(failed rejected)

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
        event :fail, transitions_to: :failed
      end
      state :completed
      state :failed
    end

    def pay(txid:)
      update(txid: txid)
    end

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end

    def update_state_by_provider!(provider_state)
      update!(provider_state: provider_state)

      confirm!  if provider_state == PAYOUT_SUCCESS_PROVIDER_STATE
      fail!     if PAYOUT_FAILED_PROVIDER_STATES.include?(provider_state)
    end
  end
end
