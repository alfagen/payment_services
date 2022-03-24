# frozen_string_literal: true

class PaymentServices::CryptoApisV2
  class Payout < ApplicationRecord
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :address, :fee, :state, presence: true

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

    def pay(request_id:)
      update(request_id: request_id)
    end

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end
  end
end
