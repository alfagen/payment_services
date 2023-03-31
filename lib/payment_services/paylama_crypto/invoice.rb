# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Invoice < ::PaymentServices::Base::CryptoInvoice
    self.table_name = 'paylama_invoices'

    alias_attribute :transaction_id, :name

    def update_state_by_transaction(transaction)
      validate_transaction_amount(transaction: transaction)
      has_transaction! if pending?
      update!(
        provider_state: transaction.status, 
        transaction_created_at: transaction.created_at,
        fee: transaction.fee
      )

      pay!(payload: transaction) if transaction.succeed?
      cancel! if transaction.failed?
    end

    private

    delegate :income_payment_system, to: :order
    delegate :token_network, to: :income_payment_system
    delegate :income_wallet, to: :order
    delegate :name, to: :income_wallet

    def validate_transaction_amount(transaction:)
      raise "#{amount.to_f} #{amount_provider_currency} is needed. But #{transaction.amount} #{transaction.currency} has come." unless transaction.valid_amount?(amount.to_f, amount_provider_currency)
    end

    def amount_provider_currency
      @amount_provider_currency ||= PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: amount_currency, token_network: token_network).provider_crypto_currency
    end
  end
end
