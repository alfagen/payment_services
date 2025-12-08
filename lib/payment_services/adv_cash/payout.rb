# frozen_string_literal: true


module PaymentServices
  class AdvCash
    class Payout < ApplicationRecord
      include Workflow

      self.table_name = 'advcash_payouts'

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

      def pay(withdrawal_id:)
        update(withdrawal_id: withdrawal_id)
      end

      def update_state_by_provider(state)
        update!(provider_state: state)

        confirm!  if success?
        fail!     if failed?
      end

      def build_note
        "#{order_payout.order.public_id}-#{order_payout.id}"
      end

      private

      def order_payout
        @order_payout ||= OrderPayout.find(order_payout_id)
      end

      def success?
        provider_state == 'COMPLETED'
      end

      def failed?
        provider_state == 'CANCELED'
      end
    end
  end
end
