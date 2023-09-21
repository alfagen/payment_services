# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PaylamaFps
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_fps_invoice(params: invoice_fps_params)
      raise Error, response['cause'] unless response['success']

      invoice.update!(
        deposit_id: response['externalID'],
        pay_url: response['formURL']
      )
    end

    def pay_invoice_url
      invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
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
        payerID: order.user_id.to_s,
        currencyID: PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: income_payment_system.currency).fiat_currency_id,
        expireAt: order.income_payment_timeout,
        amount: invoice.amount.to_i,
        clientOrderID: order.public_id.to_s,
        redirectURLs: {
          successURL: order.success_redirect,
          failURL: order.failed_redirect
        }
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
