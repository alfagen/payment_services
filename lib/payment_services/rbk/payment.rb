# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'payment_client'

module PaymentServices
  class Rbk
    class Payment < ApplicationRecord
      include Workflow
      self.table_name = 'rbk_money_payments'

      scope :ordered, -> { order(id: :desc) }

      register_currency :rub
      monetize :amount_in_cents, as: :amount, with_currency: :rub
      validates :amount_in_cents, :rbk_id, :state, presence: true

      belongs_to :invoice,
                 class_name: 'PaymentServices::Rbk::Invoice',
                 foreign_key: :rbk_money_invoice_id
      delegate :access_token, to: :invoice

      workflow_column :state
      workflow do
        state :pending do
          event :success, transitions_to: :succeed
          event :fail, transitions_to: :failed
          event :refund, transitions_to: :refunded
        end

        state :succeed do
          on_entry do
            invoice.pay!
          end
          event :refund, transitions_to: :refunded
        end
        state :failed do
          on_entry do
            invoice.cancel!
          end
        end
        state :refunded
      end

      def persist_workflow_state(new_value)
        self[:state] = new_value
        save!
      end

      def self.rbk_state_to_state(rbk_state)
        if PaymentClient::SUCCESS_STATES.include?(rbk_state)
          :succeed
        elsif PaymentClient::FAIL_STATES.include?(rbk_state)
          :failed
        elsif PaymentClient::PENDING_STATES.include?(rbk_state)
          :pending
        elsif PaymentClient::REFUND_STATES.include?(rbk_state)
          :refunded
        else
          raise("Такого статуса не существует: #{rbk_state}")
        end
      end

      def make_refund!
        response = PaymentClient.new.refund(self)
        return unless response.present?

        update!(refund_payload: response)
        refund!
        refund_payload
      end

      def refresh_info!
        response = PaymentClient.new.info(self)
        return unless response.present?

        update!(
          state: self.class.rbk_state_to_state(response['status']),
          payload: response
        )
      end

      def fetch_refunds!
        response = PaymentClient.new.refunds(self)
        # FIXME: обрабатывать данные всегда как массив или всегда как хеш
        response = response.first if response.is_a?(Array)
        update!(refund_payload: response)
      end

      def payment_tool_info
        payload.dig('payer', 'paymentToolDetails', 'cardNumberMask')
      end
    end
  end
end
