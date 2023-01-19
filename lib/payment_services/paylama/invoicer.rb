# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'currency_repository'

class PaymentServices::Paylama
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.generate_invoice(params: invoice_params)

      raise "Can't create invoice: #{response['cause']}" unless response['success']

      invoice.update!(
        deposit_id: response['billID'],
        pay_url: response['paymentURL']
      )
    end

    def pay_invoice_url
      URI.parse(invoice.reload.pay_url)
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.payment_status(payment_id: invoice.deposit_id, type: 'invoice')
      raise "Can't get payment information: #{response['cause']}" unless response['ID']

      invoice.update_state_by_provider(response['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def invoice_params
      {
        amount: invoice.amount.to_i,
        expireAt: order.income_payment_timeout,
        comment: order.public_id.to_s,
        clientIP: order.remote_ip || '',
        currencyID: CurrencyRepository.build_from(kassa_currency: income_wallet.currency).provider_currency,
        redirect: {
          successURL: order.success_redirect,
          failURL: order.failed_redirect
        }
      }
    end

    def income_wallet
      @income_wallet ||= order.income_wallet
    end

    def client
      @client ||= Client.new(api_key: income_wallet.api_key, secret_key: income_wallet.api_secret)
    end
  end
end
