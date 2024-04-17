# frozen_string_literal: true

class PaymentServices::YourPayments
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://yourpayment.pro/api'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

<<<<<<< HEAD
    def create_provider_transaction(params:)
=======
    def create_invoice(params:)
>>>>>>> master
      params.merge!(merchant_id: api_key)
      safely_parse http_request(
        url: "#{API_URL}/merchant-api/create-order",
        method: :POST,
        body: params.merge(signature: build_signature(params)).to_json,
        headers: build_headers
      )
    end

<<<<<<< HEAD
    def request_requisites(params:)
=======
    def request_payment_details(params:)
>>>>>>> master
      safely_parse http_request(
        url: "#{API_URL}/public/execute",
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )
    end

<<<<<<< HEAD
    def requisites(invoice_id:)
=======
    def payment_details(invoice_id:)
>>>>>>> master
      params = { order_id: invoice_id }
      safely_parse http_request(
        url: "#{API_URL}/public/order-details",
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )
    end

    def confirm_payment(deposit_id:)
      params = { order_id: deposit_id }
      safely_parse http_request(
        url: "#{API_URL}/public/mark-paid",
        method: :POST,
        body: params.to_json,
        headers: build_headers
      )
    end

<<<<<<< HEAD
    def transaction(transaction_id:)
      params = { merchant_id: api_key, order_id: transaction_id }
=======
    def transaction(deposit_id:)
      params = { merchant_id: api_key, order_id: deposit_id }
>>>>>>> master
      safely_parse http_request(
        url: "#{API_URL}/merchant-api/get-order",
        method: :POST,
        body: params.merge(signature: build_signature(params)).to_json,
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params)
      Digest::MD5.hexdigest("#{secret_key}+#{params.to_json}")
    end

    def build_headers
      {
        'Content-Type' => 'application/json'
      }
    end
  end
end
