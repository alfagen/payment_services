# frozen_string_literal: true

require_relative 'base_client'

class PaymentServices::CryptoApis
  module Clients
    class OmniClient < PaymentServices::CryptoApis::Clients::BaseClient
      private

      def base_url
        "#{API_URL}/bc/btc/#{currency}/#{NETWORK}"
      end
    end
  end
end
