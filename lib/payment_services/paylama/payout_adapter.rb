# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'
require_relative 'currency_repository'

class PaymentServices::Paylama
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    PAYOUT_TIME_ALIVE = 1800.seconds
    PAYSOURCE_OPTIONS = {
      'visamc'  => 'card',
      'cardh2h' => 'card',
      'qiwi'    => 'qw',
      'qiwih2h' => 'qw'
    }

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

      response = client.payment_status(payment_id: payout.withdrawal_id, type: 'withdraw')
      raise "Can't get payment information: #{response}" unless response['ID']

      payout.update_state_by_provider(response['status'])
      response
    end

    private

    attr_reader :payout
    delegate :outcome_api_key, :outcome_api_secret, to: :wallet

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.process_fiat_payout(params: payout_params)
      raise "Can't create payout: #{response}" unless response['success']

      payout.pay!(withdrawal_id: response['billID'])
    end

    def payout_params
      order = OrderPayout.find(payout.order_payout_id).order
      {
        amount: payout.amount.to_i,
        expireAt: PAYOUT_TIME_ALIVE.to_i,
        comment: "#{order.public_id}-#{payout.order_payout_id}",
        clientIP: order.remote_ip || '',
        paySourcesFilter: pay_source,
        currencyID: CurrencyRepository.build_from(kassa_currency: wallet.currency).fiat_currency_id,
        recipient: payout.destination_account
      }
    end

    def pay_source
      PAYSOURCE_OPTIONS[wallet.payment_system.payway]
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
