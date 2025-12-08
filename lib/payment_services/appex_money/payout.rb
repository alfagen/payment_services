# frozen_string_literal: true

module PaymentServices
  class AppexMoney
    class Payout < ApplicationRecord
      include Workflow
      self.table_name = 'appex_money_payouts'

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
          event :fail, transitions_to: :failed
        end
        state :completed
        state :failed
      end

      def pay(number:)
        update(number: number)
      end

      def success?
        status == 'OK'
      end

      def status_failed?
        status == 'error'
      end
    end
  end
end
