# frozen_string_literal: true

class PaymentServices::Obmenka
  class Invoice < ApplicationRecord
    include Workflow

    self.table_name = 'obmenka_invoices'

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
          order.auto_confirm!(income_amount: amount)
        end
      end
      state :cancelled
    end

    def update_state_by_provider_response(response)
      update!(provider_state: response['status'])

      pay!(payload: response)    if success?
      cancel!(payload: response) if failed?
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    def pay(payload:)
      update(payload: payload)
    end

    def cancel(payload:)
      update(payload: payload)
    end

    def success?
      provider_state == 'FINISHED'
    end

    def failed?
      provider_state == 'FAILED' || provider_state == 'CANCELED'
    end
  end
end
