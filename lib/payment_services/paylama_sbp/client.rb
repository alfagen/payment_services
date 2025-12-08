# frozen_string_literal: true

module PaymentServices
  class PaylamaSbp
    class Client < ::PaymentServices::Paylama::Client
      def create_provider_invoice(params:)
        safely_parse http_request(
          url: "#{FIAT_API_URL}/generate_invoice_fps_h2h",
          method: :POST,
          body: params.to_json,
          headers: build_headers(signature: build_signature(params))
        )
      end
    end
  end
end
