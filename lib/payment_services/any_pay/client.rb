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
      request_body = params.merge(sign: build_invoicer_signature(method_name: 'create-payment', params: params))
      safely_parse(http_request(
        url: "#{API_URL}/create-payment/#{secret_key}",
        method: :POST,
        body: request_body,
        headers: build_headers
      )).dig('result')
    end

    def transaction(deposit_id:)
      params = { project_id: PROJECT_ID, trans_id: deposit_id }
      request_body = params.merge(sign: build_invoicer_signature(method_name: 'payments', params: params))
      safely_parse(http_request(
        url: "#{API_URL}/payments/#{secret_key}",
        method: :POST,
        body: request_body,
        headers: build_headers
      )).dig('result', 'payments', deposit_id)
    end

    def create_payout(params:)
      request_body = params.merge(sign: build_payout_signature(method_name: 'create-payout', params: params))
      safely_parse(http_request(
        url: "#{API_URL}/create-payout/#{secret_key}",
        method: :POST,
        body: request_body,
        headers: build_headers
      )).dig('result')
    end

    def payout(withdrawal_id:)
      params = { trans_id: withdrawal_id }
      request_body = params.merge(sign: build_payout_signature(method_name: 'payouts', params: params))
      safely_parse(http_request(
        url: "#{API_URL}/payouts/#{secret_key}",
        method: :POST,
        body: request_body,
        headers: build_headers
      )).dig('result', 'payouts', withdrawal_id)
    end

    private

    attr_reader :api_key, :secret_key

    def build_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'multipart/form-data'
      }
    end

    def build_invoicer_signature(method_name:, params:)
      sign_string = [
        method_name, secret_key, params[:project_id], params[:pay_id],
        params[:amount], params[:currency], params[:desc], params[:method], api_key 
      ].join
      sha256_hex(sign_string)
    end

    def build_payout_signature(method_name:, params:)
      sign_string = [
        method_name, secret_key, params[:payout_id], params[:payout_type],
        params[:amount], params[:wallet], params[:commission_type], api_key 
      ].join
      sha256_hex(sign_string)
    end

    def sha256_hex(sign_string)
      Digest::SHA256.hexdigest(sign_string)
    end

    def build_request(uri:, method:, body: nil, headers: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers)
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.set_form_data(body)
      request
    end
  end
end
