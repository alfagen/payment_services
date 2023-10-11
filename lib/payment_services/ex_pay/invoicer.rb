# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::ExPay
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    PROVIDER_TOKEN = 'CARDRUBP2P'
    PROVIDER_SUBTOKEN = 'CARDRUB'
    MERCHANT_ID = '1'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_p2p_params)
      raise Error, response['description'] unless response['status'] == Invoice::INITIAL_PROVIDER_STATE

      invoice.update!(deposit_id: response['tracker_id'])
      PaymentServices::Base::Wallet.new(address: response['refer'], name: response.dig('extra_info', 'recipient_name'))
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(tracker_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status']) if transaction
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order
    delegate :callback_url, to: :income_payment_system

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_p2p_params
      {
        token: PROVIDER_TOKEN,
        sub_token: PROVIDER_SUBTOKEN,
        amount: order.income_money.to_f,
        client_transaction_id: order.public_id.to_s,
        client_merchant_id: MERCHANT_ID,
        fingerprint: "#{Rails.env}_user_id_#{order.user_id}",
        transaction_description: order.public_id.to_s
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
