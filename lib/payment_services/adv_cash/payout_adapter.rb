# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::AdvCash
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
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

      response = client.find_transaction(id: payout.withdrawal_id)

      raise "Can't get withdrawal details: #{response[:exception]}" if response[:exception]

      payout.update!(provider_state: response[:find_transaction_response][:return][:status]) if response[:find_transaction_response]
      payout.confirm! if payout.success?
      payout.fail! if payout.failed?

      response
    end

    private

    def iso_currency
      currency = wallet.currency.to_s

      currency == 'RUB' ? 'RUR' : currency
    end

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)

      params = {
        amount: amount.to_d.round(2),
        currency: iso_currency,
        walletId: destination_account,
        savePaymentTemplate: false,
        note: payout.build_note
      }
      response = client.create_payout(params: params)

      raise "Can't process payout: #{response[:exception]}" if response[:exception]

      payout.pay!(withdrawal_id: response[:send_money_response][:return]) if response[:send_money_response]
    end

    def client
      @client ||= begin
        Client.new(apiName: wallet.merchant_id, authenticationToken: wallet.api_key, accountEmail: wallet.adv_cash_merchant_email)
      end
    end
  end
end
