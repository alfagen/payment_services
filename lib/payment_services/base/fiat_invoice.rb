# frozen_string_literal: true

class PaymentServices::Base
  class FiatInvoice < ActiveRecord::Base
    include Workflow

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
      provider_state == SUCCESS_PROVIDER_STATE
    end

    def provider_failed?
      provider_state == FAILED_PROVIDER_STATE
    end
  end
end
