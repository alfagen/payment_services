# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'transaction_repository'

class PaymentServices::PaylamaCrypto
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_DELAY = 1.second
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
      transaction = find_transaction(transactions: collect_transactions)
      return if transaction.nil?

      invoice.update_state_by_transaction(transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    delegate :api_key, :api_secret, to: :api_wallet

    def collect_transactions
      created_at_from = order_public_id_in_seconds - TRANSACTION_TIME_DELAY.to_i
      created_at_to = created_at_from + order.income_payment_timeout.to_i
      response = client.transactions(created_at_from: created_at_from, created_at_to: created_at_to, type: 'invoice')
      raise "Can't get transactions: #{response['cause']}" unless response['data']

      response['data']
    end

    def find_transaction(transactions:)
      TransactionRepository.new(transactions).find_for(invoice)
    end

    def order_public_id_in_seconds
      order.public_id / 1000
    end

    def api_wallet
      @api_wallet ||= Wallet.find_by(name_group: WALLET_NAME_GROUP)
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
