# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::PaylamaCrypto
  class Invoicer < ::PaymentServices::Base::Invoicer
    WALLET_NAME_GROUP = 'PAYLAMA_CRYPTO_API_KEYS'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def wallet_address(currency:)
      response = client.create_crypto_address(currency: currency)
      raise "Can't create crypto address: #{response['cause']}" unless response['address']

      response['address']
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      created_at_from = order.public_id / 1000
      created_at_to = created_at_from + order.income_payment_timeout.to_i
      response = client.transactions(created_at_from: created_at_from, created_at_to: created_at_to, type: 'invoice')
      raise "Can't get transactions: #{response['cause']}" unless response['data']

      transaction = find_transaction(transactions: response['data'])
      return if transaction.nil?

      invoice.update_state_by_provider(transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def find_transaction(transactions:)
      transactions.find { |transaction| matches_amount?(transaction) }
    end

    def matches_amount?(transaction)
      paid_amount = Money.from_amount(transaction['amount'].to_d, transaction['currency'])
      paid_amount == invoice.amount
    end

    def api_wallet
      @api_wallet ||= Wallet.find_by(name_group: WALLET_NAME_GROUP)
    end

    def client
      @client ||= Client.new(api_key: api_wallet.api_key, secret_key: api_wallet.api_secret)
    end
  end
end
