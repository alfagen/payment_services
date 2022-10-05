# frozen_string_literal: true

class PaymentServices::MasterProcessing
  class Response
    include Virtus.model

    attribute :deposit_id, String
    attribute :pay_invoice_url, String
    attribute :source, Hash

    def self.build_from(raw_response:)
      new(
        deposit_id: build_deposit_id(raw_response),
        pay_invoice_url: build_pay_invoice_url(raw_response),
        source: raw_response
      )
    end

    def success?
      source['success']
    end

    def error_message
      source['cause']
    end

    private

    def build_deposit_id(raw_response)
      raw_response['UID'] || raw_response['billID']
    end

    def build_pay_invoice_url(raw_response)
      raw_response['paymentURL'] || raw_response['paymentLinks'].first
    end
  end
end
