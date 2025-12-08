# frozen_string_literal: true

module PaymentServices
  class Binance
    class Invoice < ApplicationRecord
      include Workflow

      BINANCE_SUCCESS = [1, 6]
      BINANCE_FAILED  = 3

      self.table_name = 'binance_invoices'

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
            order.auto_confirm!(income_amount: amount, hash: transaction_id)
          end
        end
        state :cancelled
      end

      def update_state_by_provider(state)
        update!(provider_state: state)

        pay!    if success?
        cancel! if failed?
      end

      def order
        @order ||= Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
      end

      def token_address
        order.income_payment_system.token_address.presence
      end

      private

      def success?
        BINANCE_SUCCESS.include? provider_state
      end

      def failed?
        provider_state == BINANCE_FAILED
      end
    end
  end
end
