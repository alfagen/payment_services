# frozen_string_literal: true

class PaymentServices::Exmo
  class Payout < ApplicationRecord
    include Workflow

    self.table_name = 'exmo_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :destination_account, :state, presence: true

    alias_attribute :txid, :transaction_id

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

    def pay(task_id:)
      update(task_id: task_id)
    end

    def order_fio
      order_payout.order.outcome_fio.presence || order_payout.order.outcome_unk
    end

    def update_payout_details!(transaction:)
      update!(
        provider_state: transaction.provider_state,
        transaction_id: transaction.id
      )

      confirm!  if transaction.successful?
      fail!     if transaction.failed?
    end

    private

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end
  end
end

def scan_number(number)
  count_of_digits = number.to_s.length
  if number.positive?
    "Positive: #{count_of_digits} digits"
  elsif number.negative?
    "Negative: #{count_of_digits - 1} digits"
  else 
    'Zero'
  end
end
