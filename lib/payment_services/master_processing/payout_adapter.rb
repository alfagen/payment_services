# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

module PaymentServices
  class MasterProcessing
    class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
      PAYOUT_ACCEPTED_RESPONSE = 'Accepted'

      def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:, order_payout_id:)
        make_payout(
          amount: amount,
          destination_account: destination_account,
          order_payout_id: order_payout_id
        )
      end

      def refresh_status!(payout_id)
        @payout_id = payout_id
        return if payout.pending?

        response = client.payout_status(params: { externalID: payout.withdrawal_id })

        raise "Can't get withdrawal details" unless response['statusName']

        payout.update!(provider_state: response['statusName'])
        payout.confirm! if payout.success?
        payout.fail! if payout.status_failed?

        response
      end

      def payout
        @payout ||= Payout.find_by(id: payout_id)
      end

      private

      attr_accessor :payout_id

      def make_payout(amount:, destination_account:, order_payout_id:)
        @payout_id = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id).id

        params = {
          amount: amount.to_i,
          recipient: destination_account,
          uid: order_payout_id.to_s,
          callbackURL: wallet.payment_system.callback_url
        }
        response = client.process_payout(endpoint: endpoint, params: params)
        raise "Can't process payout: #{response}" unless response['status'] == PAYOUT_ACCEPTED_RESPONSE

        payout.pay!(withdrawal_id: response['externalID'])
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end

      def endpoint
        {
          'visamc'  => 'withdraw_to_card_v2',
          'cardh2h' => 'withdraw_to_card_v2',
          'qiwi'    => 'withdraw_to_qiwi_v2',
          'qiwih2h' => 'withdraw_to_qiwi_v2'
        }[wallet.payment_system.payway]
      end
    end
  end
end
