# frozen_string_literal: true

class PaymentServices::PaylamaP2p
  class Client < ::PaymentServices::Paylama::Client
    def create_provider_invoice(params:)
      safely_parse http_request(
        url: "#{FIAT_API_URL}/generate_invoice_card_transfer",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end
  end
end
