# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'client'


module PaymentServices
  class Rbk
    class PayoutDestinationClient < PaymentServices::Rbk::Client
      TOKENIZE_URL = 'https://api.rbk.money/payres/v0/bank-cards'
      URL = 'https://api.rbk.money/wallet/v0/destinations'

      def tokenize_card(number:, exp_date:, name:)
        safely_parse http_request(
          url: TOKENIZE_URL,
          method: :POST,
          body: {
            type: 'BankCard',
            cardNumber: number,
            expDate: exp_date,
            cardHolder: name.upcase
          }
        )
      end

      def create_destination(identity:, payment_token:, destination_public_id:)
        safely_parse http_request(
          url: URL,
          method: :POST,
          body: {
            name: "Destination #{destination_public_id}",
            identity: identity.rbk_id,
            currency: 'RUB',
            resource: {
              type: 'BankCardDestinationResource',
              token: payment_token
            }
          }
        )
      end

      def info(payout_destination)
        safely_parse http_request(
          url: "#{URL}/#{payout_destination.rbk_id}",
          method: :GET
        )
      end
    end
  end
end
