# frozen_string_literal: true

class PaymentServices::MasterProcessing
  class Invoice < PaymentServices::ApplicationRecord
    include WorkflowActiverecord

    self.table_name = 'master_processing_invoices'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount

    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount, hash: deposit_id)
        end
      end
      state :cancelled
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    def update_state_by_provider(status)
      update!(provider_state: status)

      pay!    if success?
      cancel! if failed?
    end

    private

    def success?
      provider_state == 'payed'
    end

    def failed?
      provider_state == 'canceled' || provider_state == 'failed'
    end
  end
end
