# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

class PaymentServices::CryptoApis
  class Invoice < ApplicationRecord
    LTC_CONFIRMATIONS_FOR_COMPLETE = 1
    CONFIRMATIONS_FOR_COMPLETE = 2
    include Workflow
    self.table_name = 'crypto_apis_invoices'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :has_transaction, transitions_to: :with_transaction
      end
      state :with_transaction do
        on_entry do
          order.make_reserve!
        end
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount, hash: transaction_id)
        end
      end
      state :cancelled
    end

    def pay(payload:)
      update(payload: payload)
    end

    def complete_payment?
      confirmations_needed = amount_currency == 'LTC' ? LTC_CONFIRMATIONS_FOR_COMPLETE : CONFIRMATIONS_FOR_COMPLETE
      confirmations >= confirmations_needed
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end
  end
end
