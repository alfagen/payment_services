# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PayFinity
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise Error, response.dig('error', 'message') unless response['success']

      data = response['data']
      invoice.update!(deposit_id: data['trackerID'])
      PaymentServices::Base::Wallet.new(
        address: sbp? ? data['SBPPhoneNumber'] : data['cardNumber'],
        name: data['holder'],
        memo: data['bank']
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      raise Error, transaction.dig('error', 'message') unless transaction['success']

      invoice.update_state_by_provider(transaction.dig('data', 'status'))
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :card_bank, :sbp_bank, :sbp?, to: :bank_resolver

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      {
        amount: invoice.amount.to_f.to_s,
        bank: sbp? ? sbp_bank : card_bank,
        client_id: "#{Rails.env}_user_#{order.user_id}_#{order.public_id}",
        currency: invoice.amount_currency.to_s,
        description: "##{order.public_id}",
        payment_type: sbp? ? 'SBP' : 'CARD'
      }
    end

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
