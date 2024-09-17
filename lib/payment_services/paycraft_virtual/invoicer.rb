# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PaycraftVirtual
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    PAYWAY = 'Номер счета'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise Error, "Can't create invoice: #{response['description']}" if response['description'].present?
      raise Error, "Can't create invoice: #{response['message']}" if response['message'].present?

      invoice.update!(deposit_id: order.public_id.to_s)
      PaymentServices::Base::Wallet.new(
        address: response['address'],
        name: "#{response['surname']} #{response['first_name']}".presence,
        memo: response['currency_name'].presence
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice(params: { clientUniqueId: invoice.deposit_id })
      invoice.update(rate: transaction['course'].to_f)
      invoice.update_state_by_provider(transaction['status']) if amount_valid?(transaction)
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
        external_id: order.public_id.to_s,
        amount: invoice.amount.to_i,
        token_name: PAYWAY,
        currency: invoice.amount_currency.to_s
      }
    end

    def amount_valid?(transaction)
      transaction['amountPaid'] == transaction['amount'] || transaction['amountPaid'].zero?
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
