# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex


module PaymentServices
  class Rbk
    class Client
      include AutoLogger
      TIMEOUT = 10
      API_V2 = 'https://api.rbk.money/v2'
      MAX_INVOICE_LIVE = 18.minutes
      SHOP = 'TEST'
      DEFAULT_CURRENCY = 'RUB'

      private

      def http_request(url:, method:, body: nil, headers: {})
        uri = URI.parse(url)
        https = http(uri)
        request = build_request(uri: uri, method: method, body: body, headers: headers)
        logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
        https.request(request)
      end

      def build_request(uri:, method:, body: nil, headers: {})
        request = if method == :POST
                    Net::HTTP::Post.new(uri.request_uri, build_headers(headers))
                  elsif method == :GET
                    Net::HTTP::Get.new(uri.request_uri, build_headers(headers))
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

      def build_headers(headers)
        {
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'no-cache',
          'X-Request-ID': SecureRandom.hex,
          'Authorization': "Bearer #{Secrets.rbk_money_api_key}"
        }.merge(headers)
      end

      def safely_parse(response)
        JSON.parse(response.body)
      rescue JSON::ParserError => err
        logger.warn "Request failed #{response.class} #{response.body}"
        Bugsnag.notify err do |report|
          report.add_tab(:rbk_data,
                         response_class: response.class,
                         response_body: response.body)
        end
        response.body
      end
    end
  end
end
