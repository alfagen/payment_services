# frozen_string_literal: true

module PaymentServices
  class Wallex
    class Client < ::PaymentServices::Base::Client
      API_URL = 'https://wallex.online'
      MERCHANT_ID = 286

      def initialize(api_key:, secret_key:)
        @api_key = api_key
        @secret_key = secret_key
      end

      def create_invoice(params:)
        sign = signature(sign_str: sign_string(params: params, param_names: [:client, :uuid, :amount, :fiat_currency, :payment_method]))
        safely_parse http_request(
          url: "#{API_URL}/exchange/create_deal_v2/#{MERCHANT_ID}",
          method: :POST,
          body: params.merge(sign: sign).to_json,
          headers: build_headers
        )
      end

      def invoice_transaction(deposit_id:)
        safely_parse http_request(
          url: "#{API_URL}/exchange/get?id=#{deposit_id}",
          method: :GET,
          headers: build_headers
        )
      end

      def create_payout(params:)
        params[:merchant] = MERCHANT_ID
        sign = signature(sign_str: sign_string(params: params, param_names: [:merchant, :amount, :currency, :number, :bank, :type, :fiat]))
        safely_parse http_request(
          url: "#{API_URL}/payout/new",
          method: :POST,
          body: params.merge(sign: sign).to_json,
          headers: build_headers
        )
      end

      def payout_transaction(payout_id:)
        params = { merchant: MERCHANT_ID, id: payout_id }
        sign = signature(sign_str: sign_string(params: params, param_names: [:merchant, :id]))
        safely_parse http_request(
          url: "#{API_URL}/payout/get",
          method: :POST,
          body: params.merge(sign: sign).to_json,
          headers: build_headers
        )
      end

      private

      attr_reader :api_key, :secret_key

      def build_headers
        {
          'Content-Type' => 'application/json',
          'X-Api-Key' => api_key
        }
      end

      def sign_string(params:, param_names:)
        params.slice(*param_names).values.join + secret_key
      end

      def signature(sign_str:)
        Digest::SHA1.hexdigest(sign_str)
      end
    end
  end
end
