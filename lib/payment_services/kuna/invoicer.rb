# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Kuna
  class Invoicer < ::PaymentServices::Base::Invoicer
    KUNA_URL = 'https://api.kuna.io/v3/auth/merchant/deposit'
    PAYMENT_SERVICE = 'default'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def pay_invoice_url
      invoice = Invoice.find_by!(order_public_id: order.public_id)
      params = {
        amount: invoice.amount.to_f,
        currency: invoice.amount.currency.to_s.downcase,
        payment_service: PAYMENT_SERVICE
        # callback_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/kuna/receive_payment"
      }
      response = client.create_deposit(params: params)

      raise "Can't create invoice: #{response['messages']}" if response['messages']

      invoice.update!(deposit_id: response['deposit_id'])

      response['payment_url']
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
