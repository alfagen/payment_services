# frozen_string_literal: true

class PaymentServices::Blockchair
  class Invoice < ApplicationRecord
    include Workflow
    self.table_name = 'blockchair_invoices'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :bind_transaction, transitions_to: :with_transaction
      end
      state :with_transaction do
        on_entry do
          order.make_reserve!
        end
        event :pay, transitions_to: :waiting_for_kyt_verification
      end
      state :waiting_for_kyt_verification do
        on_entry do
          exec_kyt_verification!
        end
        event :kyt_verification_succeed, transitions_to: :paid
        event :kyt_verification_failed, transitions_to: :cancelled
      end
      state :paid do
        on_entry do
          order.auto_confirm!(income_amount: amount, hash: transaction_id)
        end
      end
      state :cancelled do
        on_entry do
          order.reject!(status: :rejected, reason: I18n.t('validations.kyt.failed'))
        end
      end
    end

    def pay(payload:)
      update(payload: payload)
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    def memo
      @memo ||= order.income_wallet.memo
    end

    def update_invoice_details(transaction:)
      bind_transaction! if pending?
      update!(transaction_created_at: transaction.created_at, transaction_id: transaction.id)

      pay!(payload: transaction) if transaction.successful?
    end

    private

    def exec_kyt_verification!
      if order.income_kyt_check? && kyt_verification_success?
        kyt_verification_succeed!
      else
        kyt_verification_failed!
      end
    end

    def kyt_verification_success?
      sender_address = PaymentServices::Blockchair::Invoicer.new.transaction_for(self).sender_address
      KytValidator.new(order: order, direction: :income, address: sender_address).perform
    end
  end
end
