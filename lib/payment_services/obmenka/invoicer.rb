# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Obmenka
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        payment_id: order.public_id,
        currency: payment_service,
        amount: invoice.amount.to_f,
        description: "Платеж по заявке #{order.public_id}",
        success_url: routes_helper.public_payment_status_success_url(order_id: order.public_id),
        fail_url: routes_helper.public_payment_status_fail_url(order_id: order.public_id)
      }

      response = client.create_deposit(params: params)

      raise "Can't create invoice: #{response['error']['message']}" if response['error']

      invoice.update!(deposit_id: response['tracking'])
    end

    def pay_invoice_url
      response = client.process_payment_data(public_id: invoice.order_public_id, deposit_id: invoice.deposit_id)

      raise "Can't get pay url: #{response['error']['message']}" if response['error']

      response['pay_link']
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.invoice_status(public_id: invoice.order_public_id, deposit_id: invoice.deposit_id)

      raise "Can't get invoice status: #{response['error']['message']}" if response['error']

      invoice.update_state_by_provider_response(response) if response['status']
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def payment_service
      available_options = {
        'visamc' => 'visamaster.rur',
        'qiwi'   => 'qiwi'
      }
      available_options[order.income_wallet.payment_system.payway]
    end

    def client
      @client ||= begin
        wallet = order.income_wallet

        Client.new(merchant_id: wallet.merchant_id, secret_key: wallet.api_secret)
      end
    end
  end
end
