# frozen_string_literal: true

require_relative 'payout'
require_relative 'client'

class PaymentServices::Capitalist
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    Error = Class.new StandardError

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

      transaction = client.transaction(payout_id: payout.withdrawal_id)
      payout.update_state_by_provider(transaction['state'])
      transaction
    end

    private

    attr_reader :payout

    delegate :card_bank, :sbp_bank, :sbp?, to: :resolver

    def resolver
      @resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def make_payout(amount:, destination_account:, order_payout_id:)
      @payout = Payout.create!(amount: amount, destination_account: destination_account, order_payout_id: order_payout_id)
      response = client.create_payout(batch: batch)
      raise Error, response['message'] unless response['code'] == 0

      payout.pay!(withdrawal_id: response['data']['id'])
    end

    def batch
      currency = payout.amount_currency.to_s
      currency = 'RUR' if currency == 'RUB'
      operation = sbp? ? 'SBP' : card_bank
      order = OrderPayout.find(payout.order_payout_id).order

      if sbp?
        "#{operation};#{payout.destination_account.delete_prefix('+')};#{payout.amount.to_f};#{currency};#{sbp_bank};;;#{order.user_email};#{order.public_id};Order: #{order.public_id}"
      elsif currency == 'RUR'
        last_name, first_name = order.outcome_fio.split(' ').first(2).map { |e| e.downcase.capitalize }
        "#{operation};#{payout.destination_account};#{payout.amount.to_f};#{currency};#{order.public_id};Order: #{order.public_id};#{first_name};#{last_name}"
      elsif currency == 'EUR' || currency == 'USD'
        last_name, first_name = order.outcome_fio.split(' ').first(2).map { |e| e.downcase.capitalize }
        mm, yyyy = order.payment_card_exp_date.split('/')
        "#{operation};#{payout.destination_account};#{payout.amount.to_f};#{currency};#{order.public_id};Order: #{order.public_id};#{first_name};#{last_name};;;;;#{mm};#{yyyy}"
      elsif currency == 'USDT'
        operation = PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: order.outcome_payment_system.currency, token_network: order.outcome_payment_system.token_network).getblock_currency
        "#{operation};#{payout.destination_account};#{payout.amount.to_f};#{currency};#{order.public_id};Order: #{order.public_id}"
      elsif currency == 'USDC'
        "USDCERC20;#{payout.destination_account};#{payout.amount.to_f};#{currency};#{order.public_id};Order: #{order.public_id}"
      else
        "#{operation};#{payout.destination_account};#{payout.amount.to_f};#{currency};#{order.public_id};Order: #{order.public_id}"
      end
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
