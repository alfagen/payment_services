# frozen_string_literal: true


module PaymentServices
  class CryptoApisV2
    class Invoice < ApplicationRecord
      include Workflow
      self.table_name = 'crypto_apis_invoices'

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
            order.auto_confirm!(income_amount: amount, hash: transaction_id)
          end
        end
        state :cancelled
      end

      def pay(payload:)
        update(payload: payload)
      end

      def order
        Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
      end

      def update_invoice_details!(transaction:)
        has_transaction! if pending?
        update!(
          transaction_created_at: transaction.created_at,
          transaction_id: transaction.id,
          confirmed: transaction.confirmed?
        )
        pay!(payload: transaction) if confirmed?
      end

      def merchant_id
        @merchant_id ||= order.income_wallet.merchant_id
      end
    end
  end
end
