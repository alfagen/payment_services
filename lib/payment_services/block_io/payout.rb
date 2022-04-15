# frozen_string_literal: true

class PaymentServices::BlockIo
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 1
    include Workflow
    self.table_name = 'block_io_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :address, :fee, :state, presence: true

    alias_attribute :txid, :transaction_id

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
      end
      state :paid do
        event :confirm, transitions_to: :completed
      end
      state :completed
      state :failed
    end

    def pay(transaction_id:)
      update(transaction_id: transaction_id)
    end

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end

    def update_payout_details!(transaction:)
      update!(
        transaction_created_at: transaction.transaction_created_at,
        fee: transaction.total_spend - amount.to_f,
        confirmations: transaction.confirmations
      )
      confirm! if confirmed?
    end

    private

    def confirmed?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end
  end
end
