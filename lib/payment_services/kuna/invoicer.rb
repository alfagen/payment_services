# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Kuna
  class Invoicer < ::PaymentServices::Base::Invoicer
    PAY_URL = 'https://paygate.kuna.io/hpp'

    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        amount: invoice.amount.to_f,
        currency: invoice.amount.currency.to_s.downcase,
        payment_service: payment_service,
        fields: { required_field_name => order.num_ps1 },
        return_url: routes_helper.public_payment_status_success_url(order_id: order.public_id),
        callback_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/kuna/receive_payment"
      }
      response = client.create_deposit(params: params)

      raise "Can't create invoice: #{response['messages']}" if response['messages']

      invoice.update!(
        deposit_id: response['deposit_id'],
        payment_invoice_id: response['payment_invoice_id']
      )
      invoice
    end

    def pay_invoice_url
      invoice = Invoice.find_by!(order_public_id: order.public_id)

      uri = URI.parse(PAY_URL)
      uri.query = { cpi: invoice.payment_invoice_id }.to_query

      uri
    end

    private

    def payment_service
      available_options = {
        'visamc' => "payment_card_#{invoice.amount.currency.to_s.downcase}_hpp",
        'qiwi'   => "qiwi_#{invoice.amount.currency.to_s.downcase}_hpp"
      }
      available_options[wallet.payment_system.payway]
    end

    def required_field_name
      required_field_for = {
        'visamc' => 'card_number',
        'qiwi'   => 'phone'
      }
      required_field_for[wallet.payment_system.payway]
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        Client.new(
          api_key: wallet.api_key,
          secret_key: wallet.api_secret
        )
      end
    end
  end
end
