# frozen_string_literal: true

class PaymentServices::OkoOtc
  class Client < ::PaymentServices::Base::Client
    API_URL = 'https://oko-otc.ru/api/v2/payment'

    def initialize(api_key:, secret_key:)
      @api_key    = api_key
      @secret_key = secret_key
    end

    def process_payout(params:)
      safely_parse http_request(
        url: "#{API_URL}/create_withdraw",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: build_signature(params))
      )
    end

    def payout_status(withdrawal_id:)
      params = {
        limit: 1,
        offset: 0,
        orderID: withdrawal_id,
        orderType: 'withdraw'
      }

      safely_parse http_request(
        url: "#{API_URL}/fetch_orders_v2",
        method: :POST,
        body: params.to_json,
        headers: build_headers(signature: '')
      )
    end

    private

    attr_reader :api_key, :secret_key

    def build_signature(params)
      sign_string = [params[:sum], params[:wallet], params[:orderUID], ''].join(';')
      OpenSSL::HMAC.hexdigest('SHA512', secret_key, sign_string)
    end

    def build_headers(signature:)
      {
        'Content-Type'  => 'application/json',
        'Accept'        => 'application/json',
        'Authorization' => api_key,
        'Signature'     => signature
      }
    end
  end
end
