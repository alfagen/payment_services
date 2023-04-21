# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::ExPay
  class Invoicer < ::PaymentServices::Base::Invoicer
    INVOICE_PROVIDER_TOKEN = 'CARDRUBP2P'
    INVOICE_PROVIDER_SUBTOKEN = 'TCSRUB'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
      response = client.create_invoice(params: invoice_params)

      raise "Can't create invoice: #{response['description']}" unless response['status'] == Invoice::INITIAL_PROVIDER_STATE

      invoice.update!(
        deposit_id: response['tracker_id'],
        pay_url: response['alter_refer']
      )
    end

    def pay_invoice_url
      invoice.present? ? URI.parse(invoice.reload.pay_url) : ''
    end

    def async_invoice_state_updater?
      false
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :callback_url, to: :income_payment_system

    def invoice_params
      {
        amount: invoice.amount.to_i,
        call_back_url: callback_url,
        card_number: order.income_account,
        client_transaction_id: order.public_id.to_s,
        email: order.user.email,
        token: INVOICE_PROVIDER_TOKEN,
        sub_token: INVOICE_PROVIDER_SUBTOKEN,
        transaction_description: I18n.t('payment_systems.default_product', order_id: order.public_id),
        p2p_uniform: true
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
