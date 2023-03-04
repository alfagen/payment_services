# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Invoice < ::PaymentServices::Paylama::Invoice
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
          order.auto_confirm!(income_amount: amount, hash: order.income_wallet.name)
        end
      end
      state :cancelled
    end

    def update_state_by_transaction(transaction)
      validate_transaction(transaction: transaction)
      has_transaction! if pending?
      update!(
        provider_state: transaction.status, 
        transaction_created_at: transaction.created_at,
        fee: transaction.fee
      )

      pay!(payload: transaction) if transaction.succeed?
      cancel! if transaction.failed?
    end

    def order
      Order.find_by(public_id: order_public_id) || PreliminaryOrder.find_by(public_id: order_public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :token_network, to: :income_payment_system

    def pay(payload:)
      update(payload: payload)
    end

    def validate_transaction_amount(transaction:)
      raise "#{amount.to_f} #{amount_provider_currency} is needed. But #{transaction.amount} #{transaction.currency} has come." unless transaction.valid_amount?(amount.to_f, amount_provider_currency)
    end

    def amount_provider_currency
      @amount_provider_currency ||= PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: amount_currency, token_network: token_network).provider_crypto_currency
    end
  end
end
