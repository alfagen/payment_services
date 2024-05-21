# frozen_string_literal: true

class PaymentServices::Payeer
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://payeer.com/ajax/api/api.php'

    def initialize(api_id:, api_key:, currency:, account:)
      @api_id = api_id
      @api_key = api_key
      @currency = currency
      @account = account
    end

    def create_invoice(params:)
      safely_parse http_request(
        url: API_URL + '?invoiceCreate',
        method: :POST,
        body: params.merge(
          account: account,
          apiId: api_id,
          apiPass: api_key,
          action: 'invoiceCreate'
        )
      )
    end

    def find_invoice(deposit_id:)
      safely_parse http_request(
        url: API_URL + '?paymentDetails',
        method: :POST,
        body: {
          account: account,
          apiId: api_id,
          apiPass: api_key,
          action: 'paymentDetails',
          referenceId: deposit_id
        }
      )
    end

    def create_payout(params:)
      safely_parse http_request(
        url: API_URL + '?transfer',
        method: :POST,
        body: params.merge(
          apiId: api_id,
          apiPass: api_key,
          curIn: currency,
          curOut: currency,
          action: 'transfer'
        )
      )
    end

    def payments(params:)
      safely_parse http_request(
        url: API_URL + '?history',
        method: :POST,
        body: params.merge(
          apiId: api_id,
          apiPass: api_key,
          action: 'history'
        )
      )
    end

    private

    attr_reader :api_id, :api_key, :currency, :account

    def build_request(uri:, method:, body: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri, headers)
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri, headers)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = URI.encode_www_form((body.present? ? body : {}))
      request
    end

    def headers
      {
        'content_type'  => 'application/x-www-form-urlencoded'
      }
    end
  end
end
