# frozen_string_literal: true


module PaymentServices
  class Tronscan
    class Invoice < ::PaymentServices::Base::CryptoInvoice
      self.table_name = 'tronscan_invoices'

      monetize :amount_cents, as: :amount

      def update_invoice_details(transaction:)
        bind_transaction! if pending?
        update!(transaction_created_at: transaction.created_at, transaction_id: transaction.id)

        pay!(payload: transaction) if transaction.successful?
      end
    end
  end
end
