# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'client'


module PaymentServices
  class Rbk
    class InvoiceClient < PaymentServices::Rbk::Client
      URL = "#{API_V2}/processing/invoices"

      def create_invoice(order_id:, amount:)
        request_body = {
          shopID: SHOP,
          dueDate: Time.zone.now + MAX_INVOICE_LIVE,
          amount: amount,
          currency: DEFAULT_CURRENCY,
          product: I18n.t('payment_systems.default_product', order_id: order_id),
          metadata: { order_public_id: order_id }
        }
        safely_parse http_request(
          url: URL,
          method: :POST,
          body: request_body
        )
      end

      def pay_invoice_by_customer(invoice:, customer:)
        request_body = {
          flow: { type: 'PaymentFlowInstant' },
          payer: {
            payerType: 'CustomerPayer',
            customerID: customer.rbk_id
          }
        }
        safely_parse http_request(
          url: "#{URL}/#{invoice.rbk_invoice_id}/payments",
          method: :POST,
          body: request_body,
          headers: { Authorization: "Bearer #{invoice.access_token}" }
        )
      end

      def get_info(invoice)
        safely_parse http_request(
          url: "#{URL}/#{invoice.rbk_invoice_id}",
          method: :GET,
          headers: { Authorization: "Bearer #{invoice.access_token}" }
        )
      end

      def get_payments(invoice)
        safely_parse http_request(
          url: "#{URL}/#{invoice.rbk_invoice_id}/payments",
          method: :GET,
          headers: { Authorization: "Bearer #{invoice.access_token}" }
        )
      end
    end
  end
end
