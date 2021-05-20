# frozen_string_literal: true

class PaymentServices::Liquid
  class Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://api.liquid.com'
    API_VERSION = '2'
    WALLET_NAME_GROUP = 'LIQUID_API_KEYS'

    def initialize(currency:)
      @currency = currency
    end

    def address_transactions
      request_for("/transactions?transaction_type=funding&currency=#{currency}")
    end

    def wallet
      wallets = request_for("/crypto_accounts")

      wallets.find { |w| w['currency'] == currency }
    end

    private

    attr_reader :currency

    def api_wallet
      @api_wallet = Wallet.find_by(name_group: WALLET_NAME_GROUP)
    end

    def request_for(path)
      safely_parse http_request(
        url: API_URL + path,
        method: :GET
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
                  Net::HTTP::Post.new(uri.request_uri, headers(uri.to_s.delete_prefix(API_URL)))
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers(uri.to_s.delete_prefix(API_URL)))
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

    def headers(path)
      {
        'Content-Type': 'application/json',
        'X-Quoine-API-Version': API_VERSION,
        'X-Quoine-Auth': build_signature(path)
      }
    end

    def build_signature(path)
      auth_payload = {
        path: path,
        nonce: DateTime.now.strftime('%Q'),
        token_id: api_wallet.merchant_id.to_i
      }

      JWT.encode(auth_payload, api_wallet.api_key, 'HS256')
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
