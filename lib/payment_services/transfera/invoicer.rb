# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Transfera
  class Invoicer < ::PaymentServices::Base::Invoicer
    SBP_PAYMENT_METHOD  = 'SBP'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise "#{response}" unless response['order_id']

      invoice.update!(deposit_id: response['order_id'])
      PaymentServices::Base::Wallet.new(
        address: response['card'],
        name: nil
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(transaction_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :card_bank, :sbp?, to: :bank_resolver

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      {
        amount: invoice.amount.to_i,
        currency: invoice.amount_currency.to_s,
        payload: {
          id: order.public_id.to_s
        },
        cardType: sbp? ? SBP_PAYMENT_METHOD : card_bank,
        transaction_type: 'PAY_IN'
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
