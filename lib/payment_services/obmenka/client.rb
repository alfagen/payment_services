# frozen_string_literal: true

require 'digest'
require 'base64'

class PaymentServices::Obmenka
  class Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://acquiring_api.obmenka.ua/api'

    def initialize(merchant_id:, secret_key:)
      @merchant_id = merchant_id
      @secret_key  = secret_key
    end

    def create_deposit(params:)
      safely_parse http_request(
        url: "#{API_URL}/einvoice/create",
        method: :POST,
        body: params
      )
    end

    def process_payment_data(public_id:, deposit_id:)
      safely_parse http_request(
        url: "#{API_URL}/einvoice/process",
        method: :POST,
        body: {
          payment_id: public_id,
          tracking: deposit_id
        }
      )
    end

    def invoice_status(public_id:, deposit_id:)
      safely_parse http_request(
        url: "#{API_URL}/einvoice/status",
        method: :POST,
        body: {
          payment_id: public_id,
          tracking: deposit_id
        }
      )
    end

    private

    attr_reader :merchant_id, :secret_key

    def http_request(url:, method:, body: nil)
      uri = URI.parse(url)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers(body))
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = (body.present? ? body : {}).to_json
      request
    end

    def headers(params)
      {
        'Content-Type'  => 'application/json',
        'DPAY_CLIENT'   => merchant_id,
        'DPAY_SECURE'   => signature(params: params)
      }
    end

    def http(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: TIMEOUT,
                      read_timeout: TIMEOUT)
    end

    def signature(params:)
      sign_string = params.values.join

      sign_string = Digest::SHA1.hexdigest(sign_string)
      sign_string = Base64.encode64(sign_string)
      sign_string = secret_key + sign_string + secret_key
      sign_string = Digest::MD5.hexdigest(sign_string)

      Base64.encode64(sign_string)
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
