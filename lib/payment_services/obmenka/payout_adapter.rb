# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Obmenka
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    CARD_RU_SERVICE = 'visamaster.rur'
    QIWI_SERVICE    = 'qiwi'

    Error = Class.new StandardError
    PayoutStatusRequestFailed = Class.new Error
    PayoutCreateRequestFailed = Class.new Error
    PayoutProcessRequestFailed = Class.new Error

    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
      make_payout(
        amount: amount,
        destination_account: destination_account,
        order_payout_id: order_payout_id
      )
    end

    def refresh_status!(payout_id)
      payout = Payout.find(payout_id)
      return if payout.pending?

      response = client.payout_status(public_id: payout.public_id, withdrawal_id: payout.withdrawal_id)
      raise PayoutStatusRequestFailed, "Can't get payout status: #{response['error']['message']}" if response['error']

      payout.update_state_by_provider(response['status']) if response['status']
      response
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      payout_params = {
        recipient: destination_account,
        currency: payment_service_by_payway,
        amount: amount.to_f,
        description: "Payout #{payout.public_id}",
        payment_id: payout.public_id
      }
      response = client.create_payout(params: payout_params)
      raise PayoutCreateRequestFailed, "Can't create payout: #{response['error']['message']}" if response['error']

      payout.pay!(withdrawal_id: response['tracking'])
      response = client.process_payout(public_id: payout.public_id, withdrawal_id: payout.withdrawal_id)
      raise PayoutProcessRequestFailed, "Can't process payout: #{response['error']['message']}" if response['error']
    end

    def payment_service_by_payway
      available_options = {
        'visamc' => CARD_RU_SERVICE,
        'qiwi'   => QIWI_SERVICE
      }
      available_options[wallet.payment_system.payway]
    end

    def client
      @client ||= begin
        Client.new(merchant_id: wallet.merchant_id, secret_key: wallet.outcome_api_secret)
      end
    end
  end
end
