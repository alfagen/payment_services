# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PayForU
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      invoice.update!(
        deposit_id: response['id'],
        pay_url: response.dig('integration', 'link')
      )
    end

    def pay_invoice_url
      invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(deposit_id: invoice.deposit_id)
      if transaction && amount_matched?(transaction)
        invoice.update(last_4_digits: transaction.dig('payment', 'customerCardLastDigits'))
        invoice.update_state_by_provider(transaction['status'])
      end
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :currency, to: :income_payment_system

    def invoice_params
      {
        amount: invoice.amount.to_i,
        currency: currency.to_s,
        customer: {
          id: order.user_id.to_s,
          email: order.user_email
        },
        integration: {
          externalOrderId: order.public_id.to_s,
          returnUrl: order.success_redirect
        }
      }
    end

    def amount_matched?(transaction)
      transaction['amount'].to_i == invoice.amount.to_i
    end

    def client
      @client ||= Client.new(api_key: api_key)
    end
  end
end
