# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::OkoOtc
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

      response = client.payout_status(withdrawal_id: "#{order.public_id}-#{order_payout_id}")

      raise "Can't get withdraw history. Error Code: #{response['errCode']}" unless response['totalLen']

      payout.update_state_by_provider(provider_state(response))
      response
    end

    private

    def make_payout(amount:, destination_account:, order_payout_id:)
      payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      order = OrderPayout.find(order_payout_id).order

      params = {
        sum: amount.to_i,
        currencyFrom: amount.currency.to_s,
        wallet: destination_account,
        bank: provider_bank,
        dateOfBirth: order.outcome_operator,
        orderUID: "#{order.public_id}-#{order_payout_id}"
      }
      curr = amount.currency.to_s.downcase.inquiry
      params[:cardholder] = order.outcome_fio if curr.eur? || curr.usd?
      params[:cardExpiration] = card_expiration(order) if curr.eur? || curr.azn?
      if curr.usdt?
        params[:sumInRub] = usdt_to_rub(amount: amount).to_i
        params[:sum] = 1
      end

      response = client.process_payout(params: params)
      raise "Can't create payout. Error Code: #{response['errCode']}" unless response['status']

      payout.pay!(withdrawal_id: response['orderID'])
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end

    def card_expiration(order)
      month, year = order.payment_card_exp_date.split('/')
      year.length == 2 ? "#{month}/20#{year}" : order.payment_card_exp_date
    end

    def provider_state(response)
      response['data'].first.dig('orderStats', 'statusName')
    end

    def provider_bank
      @provider_bank ||= PaymentServices::Base::P2pBankResolver.new(adapter: self, direction: :outcome).provider_bank
    end

    def usdt_to_rub(amount:)
      Gera::ExchangeRate.find_by(ps_from_id: 5, ps_to_id: 70).direction_rate.reverse_exchange(amount)
      # Gera::ExchangeRate.find_by(ps_from_id: 69, ps_to_id: 72).direction_rate.reverse_exchange(amount).to_i
    end
  end
end
