# frozen_string_literal: true

require_relative 'invoice'
require_relative 'transaction'

class PaymentServices::PaylamaCrypto
  class Invoicer < ::PaymentServices::Base::Invoicer
    WALLET_NAME_GROUP = 'PAYLAMA_CRYPTO_API_KEYS'

    def create_invoice(money)
      Invoice.create(amount: money, order_public_id: order.public_id)
    end

    def wallet_information(currency:, token_network:)
      provider_crypto_currency = PaymentServices::Paylama::CurrencyRepository.build_from(kassa_currency: currency, token_network: token_network).provider_crypto_currency
      response = client.create_crypto_address(currency: provider_crypto_currency)
      raise "Can't create crypto address: #{response['cause']}" unless response['id']

      response
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      raw_transaction = client.payment_status(payment_id: order.income_wallet.name, type: 'invoice')
      raise "Can't get payment information: #{response['cause']}" unless raw_transaction['ID']

      transaction = Transaction.build_from(raw_transaction)
      invoice.update_state_by_transaction(transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    delegate :api_key, :api_secret, to: :api_wallet

    def api_wallet
      @api_wallet ||= Wallet.find_by!(name_group: WALLET_NAME_GROUP)
    end

    def client
      @client ||= PaymentServices::Paylama::Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
