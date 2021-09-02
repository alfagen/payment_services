# frozen_string_literal: true

class PaymentServices::Binance
  class Payout < ApplicationRecord
    include Workflow

    BINANCE_SUCCESS  = 6
    BINANCE_REJECTED = 3
    BINANCE_FAILURE  = 5

    self.table_name = 'binance_payouts'

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

    def pay(withdraw_id:)
      update(withdraw_id: withdraw_id)
    end

    def update_state_by_provider(state)
      update!(provider_state: state)

      confirm!  if success?
      fail!     if status_failed?
    end

    def order_fio_out
      order.fio_out
    end

    def network
      order.outcome_payment_system.token_network
    end

    private

    def order
      @order ||= order_payout.order
    end

    def order_payout
      @order_payout ||= OrderPayout.find(order_payout_id)
    end

    def success?
      provider_state == BINANCE_SUCCESS
    end

    def status_failed?
      provider_state == BINANCE_REJECTED || provider_state == BINANCE_FAILURE
    end
  end
end
