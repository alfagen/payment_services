# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Wallex
  class Invoicer < ::PaymentServices::Base::Invoicer
    SBP_PAYMENT_METHOD  = 'sbp'
    CARD_PAYMENT_METHOD = 'c2c'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_p2p_params)
      raise response['message'] unless response['success']

      invoice.update!(deposit_id: response['id'])
      PaymentServices::Base::Wallet.new(
        address: response.dig('paymentInfo', 'paymentCredentials'),
        name: nil,
        memo: response.dig('paymentInfo', 'paymentComment')
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice_transaction(deposit_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :provider_bank, :sbp?, to: :bank_resolver

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_p2p_params
      {
        client: order.user.email,
        amount: invoice.amount.to_f.to_s,
        fiat_currency: invoice.amount_currency.to_s.downcase,
        uuid: order.public_id.to_s,
        payment_method: sbp? ? SBP_PAYMENT_METHOD : CARD_PAYMENT_METHOD,
        bank: provider_bank
      }
    end

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
