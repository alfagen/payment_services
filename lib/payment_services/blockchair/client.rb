# frozen_string_literal: true

require_relative 'blockchain'


module PaymentServices
  class Blockchair
    class Client < ::PaymentServices::Base::Client
      def initialize(api_key:, currency:)
        @api_key  = api_key
        @blockchain = Blockchain.new(currency: currency)
      end

      def transactions(address:)
        safely_parse http_request(
          url: "#{blockchain.transactions_endpoint(address)}#{api_suffix}",
          method: :GET,
          headers: build_headers
        )
      end

      def transactions_data(tx_ids:)
        safely_parse http_request(
          url: "#{blockchain.transactions_data_endpoint(tx_ids)}#{api_suffix}",
          method: :GET,
          headers: build_headers
        )
      end

      private

      attr_reader :api_key, :blockchain

      def api_suffix
        api_key ? "?key=#{api_key}" : ''
      end

      def build_headers
        {
          'Content-Type'  => 'application/json',
          'Cache-Control' => 'no-cache'
        }
      end
    end
  end
end
