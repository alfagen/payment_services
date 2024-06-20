# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Cryptomus
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise Error, "Can't create invoice: #{response['message']}" if response['message']

      invoice.update!(deposit_id: response.dig('result', 'uuid'))
      PaymentServices::Base::Wallet.new(
        address: response.dig('result', 'address'),
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
      transaction = client.transaction(params: { uuid: invoice.deposit_id })

      invoice.update(transaction_id: transaction.dig('result', 'txid'))
      invoice.update_state_by_provider(transaction.dig('result', 'payment_status'))
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      {
        amount: invoice.amount.to_f.to_s,
        currency: invoice.amount_currency.to_s,
        order_id: order.public_id.to_s,
        lifetime: order.income_payment_timeout.to_i
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
