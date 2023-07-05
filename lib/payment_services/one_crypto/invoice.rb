# frozen_string_literal: true

class PaymentServices::OneCrypto
  class Invoice < ::PaymentServices::Base::CryptoInvoice
    INITIAL_PROVIDER_STATE  = 'ACCEPTED'

    self.table_name = 'one_crypto_invoices'

    monetize :amount_cents, as: :amount

    def update_state_by_transaction!(transaction)
      validate_transaction_amount(transaction: transaction)

      has_transaction! if pending?
      update!(
        provider_state: transaction.status,
        transaction_id: transaction.transaction_id
      )
      pay!(payload: transaction) if transaction.succeed?
      cancel! if transaction.failed?
    end

    def amount_provider_currency
      @amount_provider_currency ||= PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: amount_currency, token_network: token_network).provider_crypto_currency
    end

    private

    delegate :income_payment_system, to: :order
    delegate :token_network, to: :income_payment_system

    def validate_transaction_amount(transaction:)
      raise "#{amount.to_f} #{amount_provider_currency} is needed. But #{transaction.amount} #{transaction.currency} has come." unless transaction.valid_amount?(amount.to_f, amount_provider_currency)
    end
  end
end
