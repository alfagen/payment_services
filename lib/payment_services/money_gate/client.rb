# frozen_string_literal: true

class PaymentServices::MoneyGate
  class Client < ::PaymentServices::Base::Client
    API_URL = "https://moneygate.biz/exchange"

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def create_invoice(params:)
      request_body = params.merge(sign: build_signature(params))
      safely_parse http_request(
        url: "#{API_URL}/create_deal/#{api_key}",
        method: :POST,
        body: request_body,
        headers: build_headers
      )
    end

    def transaction(deposit_id:)
      safely_parse(http_request(
        url: "#{API_URL}/get/#{deposit_id}",
        method: :GET,
        headers: build_headers
      )).dig('dealInfo')
    end

    def confirm(id:)
      safely_parse http_request(
        url: "#{API_URL}/confirm/#{id}",
        method: :POST,
        body: '',
        headers: build_headers
      )
    end

    def cancel(id:)
      safely_parse http_request(
        url: "#{API_URL}/cancel/#{id}",
        method: :POST,
        body: '',
        headers: build_headers
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params)
      sign_str = params.keys.join('+') + "+#{secret_key}"
      logger.info sign_str
      Digest::SHA1.hexdigest(sign_str)
    end

    def build_headers
      {
        'Accept' => 'application/json',
        'Content-Type' => 'application/x-www-form-urlencoded'
      }
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
