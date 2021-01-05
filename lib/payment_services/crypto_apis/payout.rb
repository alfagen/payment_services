# frozen_string_literal: true

require_relative 'payout_client'

class PaymentServices::CryptoApis
  class Payout < ApplicationRecord
    CONFIRMATIONS_FOR_COMPLETE = 2

    attribute :payout_wallets

    monetize :amount_cents, as: :amount

    workflow_column :state
    workflow do
      state :pending do
        event :pay, transitions_to: :paid
        event :confirmed, transitions_to: :completed
      end

      state :cancelled
    end

    def pay(txid:)
      update(txid: txid)
    end

    def complete_payment?
      confirmations >= CONFIRMATIONS_FOR_COMPLETE
    end

    def api_query
      {
        createTx: {
          inputs: inputs,
          outputs: outputs,
          fee: {
            value: fee
          }
        },
        wifs: wifs
      }
    end

    private

    def inputs
      payout_wallets.inject([]) do |memo, wallet| 
        memo << { address: wallet.address, value: wallet.value }
      end
    end

    def outputs
      [{ address: destination_address, value: amount_cents }]
    end
  end
end
