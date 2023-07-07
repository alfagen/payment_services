# frozen_string_literal: true

class PaymentServices::AnyPay
  class Client < ::PaymentServices::Base::Client
    PROJECT_ID = 11555
    API_URL = "https://anypay.io/api"

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      params = { project_id: PROJECT_ID }.merge(params)
      request_body = params.merge(sign: build_signature('create-payment', params))
      safely_parse(http_request(
        url: "#{API_URL}/create-payment/#{secret_key}",
        method: :POST,
        body: request_body.to_json,
        headers: build_headers
      )).dig('result')
    end

    def transaction(deposit_id:)
      params = { project_id: PROJECT_ID, trans_id: deposit_id }
      request_body = params.merge(sign: build_signature('payments', params))
      safely_parse(http_request(
        url: "#{API_URL}/payments/#{secret_key}",
        method: :POST,
        body: request_body.to_json,
        headers: build_headers
      )).dig('result', 'payments', deposit_id)
    end

    def balance
      request_body = { sign: build_signature('balance', {}) }
      safely_parse(http_request(
        url: "#{API_URL}/balance/#{secret_key}",
        method: :POST,
        body: URI.encode_www_form(request_body),
        headers: build_headers
      ))
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'multipart/form-data'
      }
    end

    def build_signature(api_method_name, params)
      sign_string = api_method_name + secret_key + api_key
      Digest::SHA256.hexdigest(sign_string)
    end
  end
end
