# frozen_string_literal: true

class PaymentServices::AnyMoney
  class Payout < ApplicationRecord
    include Workflow
    self.table_name = 'any_money_payouts'

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
      end
      state :completed
    end

    def pay(externalid:)
      update(externalid: externalid)
    end

    def complete_payout?
      return false if status.nil?

      status == 'done'
    end
  end
end
