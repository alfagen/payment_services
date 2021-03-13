# frozen_string_literal: true

require_relative 'base_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class DashClient < PaymentServices::CryptoApis::PayoutClients::BaseClient
      private

      def base_url
        "#{API_URL}/bc/dash/#{NETWORK}"
      end
    end
  end
end
