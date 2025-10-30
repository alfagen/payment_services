# frozen_string_literal: true

# Copyright (c) 2019 FINFEX https://github.com/finfex

require_relative 'payout_client'

class PaymentServices::Rbk
  class Payout < PaymentServices::ApplicationRecord
    self.table_name = 'rbk_payouts'
    Error = Class.new StandardError

    belongs_to :rbk_payout_destination,
               class_name: 'PaymentServices::Rbk::PayoutDestination',
               foreign_key: :rbk_payout_destination_id

    belongs_to :rbk_wallet,
               class_name: 'PaymentServices::Rbk::Wallet',
               foreign_key: :rbk_wallet_id

    validates :rbk_id, :rbk_payout_destination, :rbk_wallet, :amount_cents, :rbk_status, presence: true, on: :create

    def self.create_from!(destination:, wallet:, amount_cents:)
      response = PayoutClient.new.make_payout(
        payout_destination: destination,
        wallet: wallet,
        amount_cents: amount_cents
      )
      raise Error, "Rbk payout error: #{response}" unless response['status']

      create!(
        rbk_id: response['id'],
        rbk_payout_destination: destination,
        rbk_wallet: wallet,
        amount_cents: amount_cents,
        payload: response,
        rbk_status: response['status']
      )
    end

    def refresh_info!
      response = PayoutClient.new.info(self)
      return unless response.present? && response['status'].present?

      update!(
        rbk_status: response['status'],
        payload: response
      )
    end
  end
end
