# frozen_string_literal: true

# Copyright (c) 2019 FINFEX https://github.com/finfex

require_relative 'payout_destination_client'

module PaymentServices
  class Rbk
    class PayoutDestination < ApplicationRecord
      self.table_name = 'rbk_payout_destinations'
      Error = Class.new StandardError

      belongs_to :rbk_identity, class_name: 'PaymentServices::Rbk::Identity', foreign_key: :rbk_identity_id

      def self.find_or_create_from_card_details(number:, name:, exp_date:, identity:)
        tokenized_card = tokenize_card!(number: number, name: name, exp_date: exp_date)

        payout_destination = identity.rbk_payout_destinations.find_by(
          payment_token: tokenized_card['token']
        )
        return payout_destination if payout_destination.present?

        create_destination!(identity: identity, tokenized_card: tokenized_card)
      end

      def self.create_destination!(identity:, tokenized_card:)
        public_id = SecureRandom.hex(10)
        response = PayoutDestinationClient.new.create_destination(
          identity: identity,
          payment_token: tokenized_card['token'],
          destination_public_id: public_id
        )
        raise Error, "Rbk failed to create destinaion: #{response}" unless response['id']

        create!(
          rbk_identity: identity,
          rbk_id: response['id'],
          public_id: public_id,
          card_brand: tokenized_card['paymentSystem'],
          card_bin: tokenized_card['bin'],
          card_suffix: tokenized_card['lastDigits'],
          payment_token: tokenized_card['token'],
          rbk_status: response['status'],
          payload: response
        )
      end

      def self.tokenize_card!(number:, name:, exp_date:)
        response = PayoutDestinationClient.new.tokenize_card(number: number, name: name, exp_date: exp_date)
        raise Error, "Rbk tokenization error: #{response}" unless response && response['token'].present?

        response
      end

      def refresh_info!
        response = PayoutDestinationClient.new.info(self)
        update!(rbk_status: response['status'], payload: response) if response['status']
      end

      def authorized?
        rbk_status == 'Authorized'
      end
    end
  end
end
