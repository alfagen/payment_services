# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PaylamaFps
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      response = client.create_fps_invoice(params: invoice_fps_params)
      raise Error, response['cause'] unless response['success']

      invoice.update!(deposit_id: response['externalID'])
      PaymentServices::Base::Wallet.new(address: response['phoneNumber'], name: nil)
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.payment_status(payment_id: invoice.deposit_id, type: 'invoice')
      invoice.update_state_by_provider(transaction['status']) if transaction
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order

    def invoice_fps_params
      {
        clientOrderID: order.public_id.to_s,
        payerID: order.user_id.to_s,
        amount: invoice.amount.to_i,
        currencyID: PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: income_payment_system.currency).fiat_currency_id,
        expireAt: order.income_payment_timeout
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
