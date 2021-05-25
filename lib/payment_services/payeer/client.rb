# frozen_string_literal: true

class PaymentServices::Payeer
  class Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://payeer.com/ajax/api/api.php'

    def initialize(api_id:, api_key:, currency:)
      @api_id = api_id
      @api_key = api_key
      @currency = currency
    end

    def create_payout(params:)
      safely_parse http_request(
        url: API_URL + '?transfer',
        method: :POST,
        body: params.merge(
          apiId: api_id,
          apiPass: api_key,
          curIn: currency,
          curOut: currency,
          action: 'transfer'
        )
      )
    end

    def payout_status(params:)
      safely_parse http_request(
        url: API_URL + '?paymentDetails',
        method: :POST,
        body: params.merge(
          apiId: api_id,
          apiPass: api_key,
          action: 'paymentDetails'
        )
      )
    end

    private

    attr_reader :api_id, :api_key, :currency

    def http_request(url:, method:, body: nil)
      uri = URI.parse(url)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers)
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = (body.present? ? body : {}).to_json
      request
    end

    def headers
      {
        'Content-Type'  => 'application/x-www-form-urlencoded'
      }
    end

    def http(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: TIMEOUT,
                      read_timeout: TIMEOUT)
    end

    def safely_parse(response)
      res = JSON.parse(response.body)
      logger.info "Response: #{res}"
      res
    rescue JSON::ParserError => err
      logger.warn "Request failed #{response.class} #{response.body}"
      Bugsnag.notify err do |report|
        report.add_tab(:response, response_class: response.class, response_body: response.body)
      end
      response.body
    end
  end
end
