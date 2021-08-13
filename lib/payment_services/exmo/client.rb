# frozen_string_literal: true

class PaymentServices::Exmo
  class Client
    include AutoLogger
    TIMEOUT = 30
    API_URL = 'https://api.exmo.com/v1.1'

    def initialize(public_key:, secret_key:)
      @public_key = public_key
      @secret_key = secret_key
    end

    def create_payout(params:)
      safely_parse http_request(
        url: "#{API_URL}/withdraw_crypt",
        method: :POST,
        body: params.merge(nonce: nonce)
      )
    end

    def wallet_operations(currency:, type:)
      safely_parse http_request(
        url: "#{API_URL}/wallet_operations",
        method: :POST,
        body: {
          currency: currency,
          type: type,
          nonce: nonce
        }
      )
    end

    private

    attr_reader :public_key, :secret_key

    def http_request(url:, method:, body: nil)
      uri = URI.parse(url)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil)
      body = URI.encode_www_form(body || {})
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers(build_signature(body)))
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = body
      request
    end

    def headers(signature)
      {
        'Content-Type'  => 'application/x-www-form-urlencoded',
        'Key' => public_key,
        'Sign' => signature
      }
    end

    def nonce
      Time.now.strftime("%s%6N")
    end

    def build_signature(request_body)
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha512'), secret_key, request_body)
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
