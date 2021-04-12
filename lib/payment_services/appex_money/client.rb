# frozen_string_literal: true

require 'digest'
require 'securerandom'

class PaymentServices::AppexMoney
  class Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://ecommerce.test.appexmoney.com/api/'

    def initialize(num_ps:, first_secret_key:, second_secret_key:)
      @num_ps = num_ps
      @first_secret_key = first_secret_key
      @second_secret_key = second_secret_key
    end

    def create(params:)
      params = params.merge(
        account: num_ps,
        nonce: SecureRandom.hex(10)
      )
      params[:signature] = signature(params)

      safely_parse http_request(
        url: API_URL + 'payout/execute',
        method: :POST,
        body: params
      )
    end

    def get(params:)
      params = params.merge(
        account: num_ps,
        nonce: SecureRandom.hex(10)
      )
      params[:signature] = signature(params)

      safely_parse http_request(
        url: API_URL + 'payout/status',
        method: :POST,
        body: params
      )
    end

    private

    attr_reader :num_ps, :first_secret_key, :second_secret_key

    def http_request(url:, method:, body: nil)
      uri = URI.parse(url)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri)
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = (body.present? ? body : {}).to_json
      p '<<<<<<<<<<<<<<<<'
      p request.body
      p '>>>>>>>>>>>>>>>>'
      request
    end

    def http(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: TIMEOUT,
                      read_timeout: TIMEOUT)
    end

    def signature(params)
      sign_string = ''

      params.each do |_k, v| 
        sign_string += "#{v}:"
      end

      # sign_string = sign_string.upcase + "#{first_secret_key}:#{second_secret_key}".upcase
      sign_string = 'lol'

      Digest::MD5.hexdigest sign_string
    end

    def safely_parse(response)
      res = JSON.parse(response.body).with_indifferent_access
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
