# frozen_string_literal: true

class PaymentServices::CryptoApis
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 1
    include Workflow
    self.table_name = 'crypto_apis_payouts'

    scope :ordered, -> { order(id: :desc) }

    monetize :amount_cents, as: :amount
    validates :amount_cents, :address, :fee, :state, presence: true

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
      end
      state :paid do
        event :confirm, transitions_to: :completed
      end
      state :completed
      state :failed
    end

    def pay(txid:)
      update(txid: txid)
    end

    def success?
      return false if confirmations.nil?

      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end

    def wallet_fee_address
      @wallet_fee_address ||= OrderPayout.find(order_payout_id).wallet_fee_address
    end

    def wallet_fee_address_present?
      wallet_fee_address.present?
    end

    private

  end
end
