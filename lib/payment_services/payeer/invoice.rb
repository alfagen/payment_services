# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex


module PaymentServices
  class Payeer
    class Invoice < ::PaymentServices::Base::FiatInvoice
      self.table_name = 'payeer_invoices'

      monetize :amount_cents, as: :amount

      def update_state_by_provider(invoice_transactions)
        invoice_transactions_sum = invoice_transactions.sum do |transaction| 
          transaction['currency'] == amount_currency ? transaction['amount'] : 0
        end 
        pay! if invoice_transactions_sum == amount.to_f
      end
    end
  end
end
