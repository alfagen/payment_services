# frozen_string_literal: true

class PaymentServices::Base
  class CryptoInvoice < ActiveRecord::Base
    include Workflow

    scope :ordered, -> { order(id: :desc) }

    validates :amount_cents, :order_public_id, :state, :kyt_verified, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :bind_transaction, transitions_to: :with_transaction
      end
      state :with_transaction do
        on_entry do
          order.make_reserve!
        end
        event :pay, transitions_to: :paid
      end
      state :paid do
        on_entry do
          perform_kyt_verification! if order.income_kyt_check?
          if kyt_verified?
            confirm_order!
          else
            reject_order!
          end
        end
      end
      state :cancelled
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    def pay(payload:)
      update(payload: payload)
    end

    def perform_kyt_verification!
      update!(kyt_verified: kyt_verification_success?)
    end

    def kyt_verification_success?
      sender_address = PaymentServices::Blockchair::InvoicerInvoicer.new(order: order).transaction_for(self).sender_address
      KytValidator.new(order: order, direction: :income, address: sender_address).perform
    end

    def confirm_order!
      order.auto_confirm!(income_amount: amount, hash: transaction_id)
    end

    def reject_order!
      order.reject!(status: :rejected, reason: I18n.t('validations.kyt.failed'))
    end
  end
end
