# frozen_string_literal: true

# Copyright (c) 2019 FINFEX https://github.com/finfex


module PaymentServices
  class AliKassa
    class Client
      include AutoLogger
      TIMEOUT = 10
      API_URL = 'https://api.alikassa.com/v1/site'
      MAX_INVOICE_LIVE = 18.minutes
      DEFAULT_USERAGENT = 'Mozilla/5.0'

      def initialize(merchant_id:, secret:)
        @merchant_id = merchant_id
        @secret = secret
      end

      def create_deposit(payment_system:, currency:, amount:, public_id:, ip:, phone:)
        request_body = {
          merchantUuid: merchant_id,
          orderId: public_id.to_s,
          phone: phone,
          amount: amount.to_s,
          currency: currency,
          desc: I18n.t('payment_systems.default_product', order_id: public_id),
          lifetime: MAX_INVOICE_LIVE.to_i,
          paySystem: payment_system,
          ip: ip,
          userAgent: DEFAULT_USERAGENT
        }

        safely_parse http_request(
          url: "#{API_URL}/deposit",
          method: :POST,
          body: request_body
        )
      end

      private

      attr_reader :merchant_id, :secret

      def http_request(url:, method:, body: nil, headers: {})
        uri = URI.parse(url)
        https = http(uri)
        request = build_request(uri: uri, method: method, body: body, headers: headers)
        logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
        https.request(request)
      end

      def build_request(uri:, method:, body: nil, headers: {})
        request = if method == :POST
                    Net::HTTP::Post.new(uri.request_uri, build_headers(headers, body))
                  elsif method == :GET
                    Net::HTTP::Get.new(uri.request_uri, build_headers(headers, body))
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

      def build_headers(headers, body)
        {
          'Content-Type': 'application/json; charset=utf-8',
          'Cache-Control': 'no-cache',
          'Authorization': "Basic #{auth_token(body)}"
        }.merge(headers)
      end

      def auth_token(params)
        sign_string = params.sort_by { |k, _v| k }.map(&:last).join(':') + ":#{secret}"
        sign_hash = Digest::MD5.base64digest(sign_string)
        Base64.urlsafe_encode64("#{merchant_id}:#{sign_hash}")
      end

      def safely_parse(response)
        JSON.parse(response.body)
      rescue JSON::ParserError => err
        logger.warn "Request failed #{response.class} #{response.body}"
        Bugsnag.notify err do |report|
          report.add_tab(:alikassa, response_class: response.class, response_body: response.body)
        end
        response.body
      end
    end
  end
end
