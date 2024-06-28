# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Paycraft
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise Error, "Can't create invoice: #{response['description']}" if response['description'].present?

      invoice.update!(deposit_id: response['external_id'])
      PaymentServices::Base::Wallet.new(
        address: response['address'],
        name: nil,
        memo: response['currency_name'].presence
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice(params: { clientUniqueId: invoice.deposit_id })
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :sbp_bank, :card_bank, :sbp?, to: :bank_resolver

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      {
        external_id: order.public_id.to_s,
        amount: invoice.amount.to_i,
        token_name: sbp? ? sbp_bank : card_bank
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
