# frozen_string_literal: true


module PaymentServices
  class Kuna
    class Client
      include AutoLogger
      TIMEOUT = 30
      API_URL = 'https://api.kuna.io'

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_deposit(params:)
        safely_parse http_request(
          url: API_URL + '/v3/auth/merchant/deposit',
          method: :POST,
          body: params
        )
      end

      def create_payout(params:)
        safely_parse http_request(
          url: API_URL + '/v3/auth/withdraw',
          method: :POST,
          body: params
        )
      end

      def payout_status(params:)
        safely_parse http_request(
          url: API_URL + '/v3/auth/withdraw/details',
          method: :POST,
          body: params
        )
      end

      private

      attr_reader :api_key, :secret_key

      def http_request(url:, method:, body: nil)
        uri = URI.parse(url)
        https = http(uri)
        request = build_request(uri: uri, method: method, body: body)
        logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
        https.request(request)
      end

      def build_request(uri:, method:, body: nil)
        request = if method == :POST
                    Net::HTTP::Post.new(uri.request_uri, headers(uri.to_s, body))
                  elsif method == :GET
                    Net::HTTP::Get.new(uri.request_uri)
                  else
                    raise "Запрос #{method} не поддерживается!"
                  end
        request.body = (body.present? ? body : {}).to_json
        request
      end

      def headers(url, params)
        nonce = time_now_milliseconds

        {
          'Content-Type'  => 'application/json',
          'kun-nonce'     => nonce,
          'kun-apikey'    => api_key,
          'kun-signature' => signature(url: url, params: params, nonce: nonce)
        }
      end

      def time_now_milliseconds
        Time.now.strftime("%s%3N")
      end

      def http(uri)
        Net::HTTP.start(uri.host, uri.port,
                        use_ssl: true,
                        verify_mode: OpenSSL::SSL::VERIFY_NONE,
                        open_timeout: TIMEOUT,
                        read_timeout: TIMEOUT)
      end

      def signature(url:, params:, nonce:)
        url.slice!(API_URL)
        sign_string = url + nonce + params.to_json

        OpenSSL::HMAC.hexdigest('SHA384', secret_key, sign_string)
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
end
