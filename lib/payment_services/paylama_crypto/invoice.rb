# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Invoice < ApplicationRecord
    SUCCESS_PROVIDER_STATE  = 'Succeed'
    FAILED_PROVIDER_STATE   = 'Failed'

    include Workflow

    self.table_name = 'paylama_invoices'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount

    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :has_transaction, transitions_to: :with_transaction
      end
      state :with_transaction do
        on_entry do
          order.make_reserve!
        end
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          # ?
          order.auto_confirm!(income_amount: amount, hash: payload)
        end
      end
      state :cancelled
    end

    def update_state_by_provider(transaction)
      has_transaction! if pending?
      update!(provider_state: transaction['status'])

      pay!(payload: transaction) if provider_succeed?
      cancel! if provider_failed?
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    def pay(payload:)
      update(payload: payload)
    end

    def provider_succeed?
      provider_state == SUCCESS_PROVIDER_STATE
    end

    def provider_failed?
      provider_state == FAILED_PROVIDER_STATE
    end
  end
end
