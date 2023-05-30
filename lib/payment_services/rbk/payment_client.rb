# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'client'

class PaymentServices::Rbk
  class PaymentClient < PaymentServices::Rbk::Client
    STATES = %w[pending processed captured cancelled refunded failed].freeze
    SUCCESS_STATES = %w[processed captured].freeze
    FAIL_STATES = %w[cancelled failed].freeze
    REFUND_STATES = %w[refunded].freeze
    PENDING_STATES = %w[pending].freeze

    def refund(payment)
      safely_parse http_request(
        url: "#{url(payment)}/refunds",
        method: :POST
      )
    end

    def info(payment)
      safely_parse http_request(
        url: url(payment),
        method: :GET
      )
    end

    def refunds(payment)
      safely_parse http_request(
        url: "#{url(payment)}/refunds",
        method: :GET
      )
    end

    private

    def url(payment)
      "#{API_V2}/processing/invoices/#{payment.invoice.rbk_invoice_id}/payments/#{payment.rbk_id}"
    end
  end
end
