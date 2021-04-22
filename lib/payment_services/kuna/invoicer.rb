# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Kuna
  class Invoicer < ::PaymentServices::Base::Invoicer
    PAY_INVOICE_URL = 'https://pay.kuna.io/hpp/?cpi='
    PAYMENT_SERVICE = 'payment_card_rub_hpp'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def pay_invoice_url
      invoice = Invoice.find_by!(order_public_id: order.public_id)
      params = {
        amount: invoice.amount.to_f,
        currency: invoice.amount.currency.to_s.downcase,
        payment_service: PAYMENT_SERVICE,
        fields: { card_number: order.num_ps1 },
        callback_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/kuna/receive_payment"
      }
      response = client.create_deposit(params: params)

      raise "Can't create invoice: #{response['messages']}" if response['messages']

      invoice.update!(deposit_id: response['deposit_id'])

      PAY_INVOICE_URL + response['payment_invoice_id']
    end

    private

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
