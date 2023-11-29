# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'currency_repository'

class PaymentServices::Paylama
  class Invoicer < ::PaymentServices::Base::Invoicer
    P2P_BANK_NAME = 'tinkoff'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      response = client.create_p2p_invoice(params: invoice_p2p_params)
      PaymentServices::Base::Wallet.new(address: response['cardNumber'], name: response['cardHolderName'])
    end

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_fiat_invoice(params: invoice_params)
      raise "Can't create invoice: #{response['cause']}" unless response['success']

      invoice.update!(
        deposit_id: response['billID'],
        pay_url: response['paymentURL']
      )
    end

    def pay_invoice_url
      (invoice.present? && invoice.reload.pay_url.present?) ? URI.parse(invoice.pay_url) : ''
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.payment_status(payment_id: invoice.deposit_id, type: 'invoice')
      raise 'Empty paylama response' unless response&.dig('ID')

      invoice.update_state_by_provider(response['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def invoice_params
      {
        amount: invoice.amount.to_i,
        expireAt: order.income_payment_timeout,
        comment: order.public_id.to_s,
        clientIP: order.remote_ip || '',
        currencyID: invoice_fiat_currency_id,
        redirect: {
          successURL: order.success_redirect,
          failURL: order.failed_redirect
        }
      }
    end

    def invoice_p2p_params
      {
        bankName: P2P_BANK_NAME,
        amount: order.income_money.to_i,
        comment: order.public_id.to_s,
        currencyID: invoice_fiat_currency_id
      }
    end

    def invoice_fiat_currency_id
      @invoice_fiat_currency_id ||= CurrencyRepository.build_from(kassa_currency: order.income_payment_system.currency).fiat_currency_id
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
