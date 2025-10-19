# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'payment'
require_relative 'invoice_client'

class PaymentServices::Rbk
  class Invoice < PaymentServices::ApplicationRecord
    include WorkflowActiverecord
    self.table_name = 'rbk_money_invoices'

    scope :ordered, -> { order(id: :desc) }

    has_many :payments,
             class_name: 'PaymentServices::Rbk::Payment',
             foreign_key: :rbk_money_invoice_id,
             dependent: :destroy

    register_currency :rub
    monetize :amount_in_cents, as: :amount, with_currency: :rub
    validates :amount_in_cents, :order_public_id, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :cancel, transitions_to: :cancelled
      end

      state :paid do
        on_entry do
          fetch_payments!
          order.auto_confirm!(income_amount: amount)
        end
      end
      state :cancelled
      state :refunded
    end

    # FIXME: в приложение
    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    def make_payment(customer)
      response = InvoiceClient.new.pay_invoice_by_customer(customer: customer, invoice: self)
      find_or_create_payment!(response)
    end

    def refresh_info!
      response = InvoiceClient.new.get_info(self)
      return unless response.present?

      update!(payload: response)
      return unless pending?

      case response['status']
      when 'paid' then pay!
      when 'cancelled' then cancel!
      end
    end

    def make_refund!
      fetch_payments! if payments.empty?
      payments.map(&:make_refund!).join(' ')
    end

    def fetch_payments!
      response = InvoiceClient.new.get_payments(self)
      response.map { |payment_json| find_or_create_payment!(payment_json) }
    end

    private

    def find_or_create_payment!(payment_json)
      payment = payments.find_by(rbk_id: payment_json['id'])
      return payment if payment.present?

      Payment.create!(
        rbk_id: payment_json['id'],
        invoice: self,
        order_public_id: order_public_id,
        amount_in_cents: payment_json['amount'],
        state: Payment.rbk_state_to_state(payment_json['status']),
        payload: payment_json
      )
    end
  end
end
