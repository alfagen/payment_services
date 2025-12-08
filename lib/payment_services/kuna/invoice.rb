# frozen_string_literal: true


module PaymentServices
  class Kuna
    class Invoice < ApplicationRecord
      FEE_PERCENT = 0.5
      UAH_FEE_PERCENT = 1.0
      UAH_FEE_REGULAR = 5
      KOPECK_EPSILON = 1

      include Workflow

      self.table_name = 'kuna_invoices'

      scope :ordered, -> { order(id: :desc) }

      monetize :amount_cents, as: :amount

      validates :amount_cents, :order_public_id, :state, presence: true

      workflow_column :state
      workflow do
        state :pending do
          event :pay, transitions_to: :paid
          event :cancel, transitions_to: :cancelled
        end

        state :paid do
          on_entry do
            order.auto_confirm!(income_amount: amount, hash: deposit_id)
          end
        end
        state :cancelled
      end

      def can_be_confirmed?(income_money:)
        pending? && amount_matches?(income_money)
      end

      def pay(payload:)
        update(payload: payload)
      end

      def order
        Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
      end

      private

      def amount_matches?(income_amount)
        (amount - income_amount - fee) <= Money.new(KOPECK_EPSILON, amount.currency)
      end

      def fee
        if amount_currency == 'UAH'
          amount * UAH_FEE_PERCENT / 100 + Money.from_amount(UAH_FEE_REGULAR, amount_currency)
        else
          amount * FEE_PERCENT / 100
        end
      end
    end
  end
end
