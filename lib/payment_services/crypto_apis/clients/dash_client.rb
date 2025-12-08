# frozen_string_literal: true

require_relative 'base_client'

module PaymentServices
  class CryptoApis
    module Clients
      class DashClient < PaymentServices::CryptoApis::Clients::BaseClient
        private

        def base_url
          "#{API_URL}/bc/dash/#{NETWORK}"
        end
      end
    end
  end
end
