# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PandaPay
  class Invoicer < ::PaymentServices::Base::Invoicer
    CURRENCY_TO_COUNTRY = {
      'KZT' => 'KAZ',
      'AZN' => 'AZE',
      'TJS' => 'TJK'
    }

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise response['error'] if response['error']

      invoice.update!(deposit_id: response['uuid'])
      requisite_data = response['requisite_data']

      PaymentServices::Base::Wallet.new(
        address: requisite_data['requisites'],
        name: requisite_data['owner_full_name'],
        memo: requisite_data['bank_name_ru']
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      {
        amount_rub: invoice.amount.to_f.round(2),
        countries: [CURRENCY_TO_COUNTRY[invoice.amount_currency.to_s]],
        currency: invoice.amount_currency.to_s,
        merchant_order_id: order.public_id.to_s,
        requisite_type: 'card',
        idempotency_key: SecureRandom.uuid
      }
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
