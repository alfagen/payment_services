# frozen_string_literal: true

class PaymentServices::Base
  class FiatInvoice < PaymentServices::ApplicationRecord
    self.abstract_class = true

    include WorkflowActiverecord

    scope :ordered, -> { order(id: :desc) }

    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount)
        end
      end
      state :cancelled
    end

    def update_state_by_provider(state)
      update!(provider_state: state)

      pay! if provider_succeed?
      cancel! if provider_failed?
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
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
