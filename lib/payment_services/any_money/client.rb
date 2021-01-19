# frozen_string_literal: true

class PaymentServices::AnyMoney
  class Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://api.any.money'
    API_VERSION = '2.0'

    def initialize(merchant_id:, api_key:)
      @merchant_id = merchant_id
      @api_key = api_key
    end

    def create(params:)
      request_for('payout.create', params)
    end

    def calculate(params:)
      request_for('payout.calc', params)
    end

    def get(params:)
      request_for('payout.get', params)
    end

    private

    attr_reader :merchant_id, :api_key

    def request_for(method, params)
      safely_parse http_request(
        url: API_URL,
        method: :POST,
        body: {
          'method': method,
          'params': params,
          'jsonrpc': API_VERSION,
          'id': ''
        }
      )
    end

    def http_request(url:, method:, body: nil)
      uri = URI.parse(url)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers(body['params']))
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers(body['params']))
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = (body.present? ? body : {}).to_json
      request
    end

    def http(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: TIMEOUT,
                      read_timeout: TIMEOUT)
    end

    def headers(params)
      utc_now = Time.now.utc * 1000

      {
        'Content-Type': 'application/json',
        'x-merchant': merchant_id,
        'x-signature': build_signature(params, utc_now),
        'x-utc-now-ms': utc_now
      }
    end

    def build_signature(params, utc_now)
      sign_string = params.sort_by { |k, _v| k }.map(&:last).join.downcase + utc_now.to_s

      OpenSSL::HMAC.hexdigest('SHA512', api_key, sign_string)
    end

    def safely_parse(response)
      JSON.parse(response.body).with_indifferent_access
    rescue JSON::ParserError => err
      logger.warn "Request failed #{response.class} #{response.body}"
      Bugsnag.notify err do |report|
        report.add_tab(:response, response_class: response.class, response_body: response.body)
      end
      response.body
    end
  end
end
