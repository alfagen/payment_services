# frozen_string_literal: true


module PaymentServices
  class Payeer
    class Payout < ApplicationRecord
      include Workflow

      self.table_name = 'payeer_payouts'

      scope :ordered, -> { order(id: :desc) }

      monetize :amount_cents, as: :amount
      validates :amount_cents, :destination_account, :state, presence: true

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

      def pay
        update(reference_id: build_reference_id)
      end

      def update_provider_state(provider_state)
        update!(provider_state: provider_state)

        confirm!  if success?
        fail!     if failed?
      end

      def order_payout
        @order_payout ||= OrderPayout.find(order_payout_id)
      end

      def build_reference_id
        "#{order_payout.order.public_id}-#{order_payout.id}"
      end

      private

      def success?
        provider_state == 'success'
      end

      def failed?
        provider_state == 'canceled'
      end
    end
  end
end
