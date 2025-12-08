# frozen_string_literal: true

require_relative 'base_client'

module PaymentServices
  class CryptoApis
    module Clients
      class EthereumClient < PaymentServices::CryptoApis::Clients::BaseClient
        def transaction_details(transaction_id)
          safely_parse http_request(
            url: "#{base_url}/txs/basic/hash/#{transaction_id}",
            method: :GET
          )
        end
      end
    end
  end
end
