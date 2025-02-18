# frozen_string_literal: true

require_relative 'client'
require_relative 'invoice'
require_relative 'transaction'

class PaymentServices::Ff
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    SUCCESS_REQUEST_STATUS_CODE = 0

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise Error, "Can't create invoice: #{response['msg']}" if response['code'] != SUCCESS_REQUEST_STATUS_CODE

      invoice.update!(deposit_id: response.dig('data', 'id'), access_token: response.dig('data', 'token'))
      PaymentServices::Base::Wallet.new(
        address: response['data']['from']['address'],
        name: nil,
        memo: response['data']['from']['tag'].presence
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      raw_transaction = client.transaction(params: { id: invoice.deposit_id, token: invoice.access_token })
      transaction = Transaction.build_from(raw_transaction['data'])
      invoice.update_state_by_transaction(transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      type = order.exchange_rate_flexible_rate? && order.flexible_rate? ? 'float' : 'fixed'
      from = order.income_currency.to_s
      from = 'BSC' if from == 'BNB'
      params = {
        type: type,
        fromCcy: from,
        toCcy: order.outcome_currency.to_s,
        direction: 'from',
        amount: invoice.amount.to_f,
        toAddress: order.outcome_account
      }
      params[:tag] = order.outcome_unk if order.outcome_unk.present?
      params
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
