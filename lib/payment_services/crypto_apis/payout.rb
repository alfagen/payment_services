# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 2
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    belongs_to :wallet

    scope :ordered, -> { order(id: :desc) }

    validates :amount, :address, :fee, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
      end
      state :paid do
        event :confirm, transitions_to: :completed
      end
      state :completed
    end

    def pay(txid:)
      update(txid: txid)
    end

    def complete_payout?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end
  end
end
