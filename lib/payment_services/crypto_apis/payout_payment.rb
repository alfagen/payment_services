# frozen_string_literal: true

class PaymentServices::CryptoApis
  class PayoutPayment < ApplicationRecord
    include Workflow
    self.table_name = 'crypto_apis_payout_payments'

    belongs_to :wallet
    belongs_to :payout

    validates :amount, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
      end
      state :paid
    end
  end
end
