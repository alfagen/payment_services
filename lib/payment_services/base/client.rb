# frozen_string_literal: true

class PaymentServices::Base
  class Client
    include AutoLogger
    TIMEOUT = 30

    def http_request(url:, method:, body: nil, headers: nil)
      uri = URI.parse(url)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body, headers: headers)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil, headers: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers)
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = body
      request
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
    rescue JSON::ParserError, TypeError => err
      logger.warn "Request failed #{response.class} #{response.body}"
      response.body
    end

    private

    def build_headers(*)
      raise 'not implemented'
    end
  end
end
