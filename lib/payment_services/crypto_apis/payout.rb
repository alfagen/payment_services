# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 2
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    has_many :payout_payments
    has_many :wallets, through: :payout_payments

    scope :ordered, -> { order(id: :desc) }

    validates :amount, :address, :fee, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :confirmed, transitions_to: :completed
      end
      state :paid
      state :completed
      state :cancelled
    end

    def pay(txid:)
      update(txid: txid)
    end

    def complete_payout?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end
  end
end
