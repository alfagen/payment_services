# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Obmenka
  class Invoicer < ::PaymentServices::Base::Invoicer
    CARD_RU_SERVICE = 'visamaster.rur'
    QIWI_SERVICE    = 'qiwi'
    INVOICE_FEE_PERCENTS = {
      'visamc' => 3,
      'qiwi'   => 2
    }

    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_deposit(params: build_invoice_params)
      raise "Can't create invoice: #{response['error']['message']}" if response['error']
      invoice.update!(deposit_id: response['tracking'])

      response = client.process_payment_data(public_id: invoice.order_public_id, deposit_id: invoice.deposit_id)
      raise "Can't get pay url: #{response['error']['message']}" if response['error']
      invoice.update!(pay_url: response['pay_link'])
    end

    def pay_invoice_url
      invoice.reload.pay_url
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.invoice_status(public_id: invoice.order_public_id, deposit_id: invoice.deposit_id)
      raise "Can't get invoice status: #{response['error']['message']}" if response['error']

      invoice.update_state_by_provider(response['status']) if response['status']
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def build_invoice_params
      {
        payment_id: order.public_id.to_s,
        currency: payment_service_by_payway,
        amount: amount_with_fee.to_f,
        description: "Payment for #{order.public_id}",
        sender: order.income_account,
        success_url: routes_helper.public_payment_status_success_url(order_id: order.public_id),
        fail_url: routes_helper.public_payment_status_fail_url(order_id: order.public_id)
      }
    end

    def amount_with_fee
      invoice.amount - invoice.amount * INVOICE_FEE_PERCENTS[order.income_wallet.payment_system.payway] / 100
    end

    def payment_service_by_payway
      available_options = {
        'visamc' => CARD_RU_SERVICE,
        'qiwi'   => QIWI_SERVICE
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
