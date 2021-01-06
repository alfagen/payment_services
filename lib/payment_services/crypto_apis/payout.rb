# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 2
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    has_many :payout_payments
    has_many :wallets, through: :payout_payments

    scope :ordered, -> { order(id: :desc) }

    validates :amount, :destination_address, :fee, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :confirmed, transitions_to: :completed
      end
      state :paid
      state :completed do
        on_entry do
          payout_payments.each(&:pay!)
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
