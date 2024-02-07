# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PaylamaP2p
  class Invoicer < ::PaymentServices::Base::Invoicer
    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_provider_invoice(params: invoice_p2p_params)
      raise response['cause'] unless response['success']

      invoice.update!(deposit_id: response['externalId'])
      PaymentServices::Base::Wallet.new(
        address: response['cardNumber'],
        name: response['cardHolderName'],
        memo: PROVIDER_BANK_NAME.capitalize
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.payment_status(payment_id: invoice.deposit_id, type: 'invoice')
      invoice.update_state_by_provider(transaction['status']) if valid_transaction?(transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :income_payment_system, to: :order

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_p2p_params
      {
        clientOrderID: order.public_id.to_s,
        payerID: "#{Rails.env}_user_id_#{order.user_id}",
        amount: invoice.amount.to_i,
        bankName: provider_bank,
        comment: "Order #{order.public_id}",
        currencyID: currency_id,
        expireAt: order.income_payment_timeout
      }
    end

    def valid_transaction?(transaction)
      transaction && transaction['amount'].to_i == invoice.amount.to_i
    end

    def provider_bank
      @provider_bank ||= PaymentServices::Base::P2pBankResolver.new(adapter: self).provider_bank
    end

    def currency_id
      @currency_id ||= Paylama::CurrencyRepository.build_from(kassa_currency: order.income_payment_system.currency).fiat_currency_id
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
