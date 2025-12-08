# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class AdvCash
    class Invoice < ::PaymentServices::Base::FiatInvoice
      SUCCESS_PROVIDER_STATE  = 'COMPLETED'
      FAILED_PROVIDER_STATES  = %w(EXPIRED CANCELED)

      self.table_name = 'adv_cash_invoices'

      monetize :amount_cents, as: :amount

      def formatted_amount
        format('%.2f', amount.to_f)
      end

      private

      def provider_succeed?
        provider_state == SUCCESS_PROVIDER_STATE
      end

      def provider_failed?
        provider_state.in? FAILED_PROVIDER_STATES
      end
    end
  end
end
