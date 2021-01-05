# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 2
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :order_public_id, :fee, :destination_address, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :confirmed, transitions_to: :completed
      end
      state :completed do
        on_entry do
          # кидаем заявку в завершенные?

        end
      end
      state :cancelled
    end

    def pay(txid:)
      update(txid: txid)
    end

    def complete_payment?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end
  end
end
