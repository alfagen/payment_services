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
      params[:signature] = create_signature(params)

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
      params[:signature] = refresh_signature(params)

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
        'Content-Type': 'application/json'
      }
    end

    def http(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: TIMEOUT,
                      read_timeout: TIMEOUT)
    end

    def create_signature(params)
      card_number = params[:params]
      masked_params = card_number[0..5] + '*' * 6 + card_number[-4..card_number.length]
      sign_string = "#{params[:nonce]}:#{params[:account]}:#{params[:operator]}:#{masked_params}:#{params[:amount]}:#{params[:amountcurr]}:#{params[:number]}"

      sign_string = sign_string + ":#{first_secret_key}:#{second_secret_key}"

      Digest::MD5.hexdigest(sign_string).upcase
    end

    def refresh_signature(params)
      sign_string = "#{params[:nonce]}:#{params[:account]}:#{params[:number]}: "

      sign_string = sign_string + ":#{first_secret_key}:#{second_secret_key}"

      Digest::MD5.hexdigest(sign_string).upcase
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
