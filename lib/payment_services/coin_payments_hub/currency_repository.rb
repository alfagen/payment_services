# frozen_string_literal: true

module PaymentServices
  class CoinPaymentsHub
    class CurrencyRepository
      TOKEN_NETWORK_TO_PROVIDER_TOKEN_ID = { 
        erc20: 'd08addf2-8af2-4bc0-9a4e-880fced2f0a0',
        trc20: '2e0dc850-4b02-49a2-a1ae-6a3ea1daf344'
      }.stringify_keys.freeze
      TOKEN_NETWORK_TO_PROVIDER_NETWORK_ID = { 
        erc20: '808977fc-9a72-4725-b723-bde4c995dba4',
        trc20: '51d1d35b-8d73-4384-aa7d-fad09de2c1dc'
      }.stringify_keys.freeze
      Error = Class.new StandardError

      include Virtus.model

      attribute :token_network, String

      def self.build_from(token_network:)
        new(token_network: token_network)
      end

      def provider_token
        TOKEN_NETWORK_TO_PROVIDER_TOKEN_ID[token_network] || raise_token_network_invalid!
      end

      def provider_network
        TOKEN_NETWORK_TO_PROVIDER_NETWORK_ID[token_network] || raise_token_network_invalid!
      end

      private

      def raise_token_network_invalid!
        raise Error, 'Token network invalid'
      end
    end
  end
end
