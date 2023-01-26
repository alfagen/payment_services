# frozen_string_literal: true

class PaymentServices::PaylamaCrypto
  class Client < ::PaymentServices::Paylama::Client
    TRANSACTIONS_LIST_LIMIT = 10
    TRANSACTIONS_LIST_OFFSET = 0
    CRYPTO_API_URL = 'https://admin.paylama.io/api/crypto'

    def create_crypto_address(currency:)
      params = { currency: currency }
      safely_parse http_request(
        url: "#{CRYPTO_API_URL}/payment",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def process_payout(params:)
      safely_parse http_request(
        url: "#{CRYPTO_API_URL}/payout",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def transactions(created_at_from:, created_at_to:, type:)
      params = {
        createdAtFrom: created_at_from,
        createdAtTo: created_at_to,
        orderType: type,
        limit: TRANSACTIONS_LIST_LIMIT,
        offset: TRANSACTIONS_LIST_OFFSET
      }
      safely_parse http_request(
        url: "#{API_URL}/fetch_orders",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end
  end
end
