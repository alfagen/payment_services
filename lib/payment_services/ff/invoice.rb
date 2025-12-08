# frozen_string_literal: true

module PaymentServices
  class Ff
    class Invoice < ::PaymentServices::Base::CryptoInvoice
      self.table_name = 'ff_invoices'

      monetize :amount_cents, as: :amount

      def update_state_by_transaction(transaction)
        bind_transaction! if pending?
        update!(
          transaction_id: transaction.id,
          provider_state: transaction.status
        )

        pay!(payload: transaction) if transaction.income_succeed?
        cancel! if transaction.failed?
      end

      def transaction_created_at
        nil
      end
    end
  end
end
