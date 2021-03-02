# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'clients/client'
require_relative 'clients/ethereum_client'
require_relative 'clients/omni_client'

class PaymentServices::CryptoApis
  class Invoicer < ::PaymentServices::Base::Invoicer
    SPECIFIC_CLIENTS = {
      'eth'   => 'EthereumClient',
      'etc'   => 'EthereumClient',
      'omni'  => 'OmniClient'
    }

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      update_invoice_details(invoice: invoice, transaction: transaction)
      invoice.pay!(payload: transaction) if invoice.complete_payment?
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def update_invoice_details(invoice:, transaction:)
      invoice.transaction_created_at ||= Time.parse(transaction[:datetime])
      invoice.transaction_id ||= transaction[:txid] || transaction[:hash]
      invoice.confirmations = transaction[:confirmations]
      invoice.save!
    end

    def transaction_for(invoice)
      if invoice.transaction_id
        client.transaction_details(invoice.transaction_id)[:payload]
      else
        response = client.address_transactions(invoice.address)
        raise response[:meta][:error][:message] if response.dig(:meta, :error, :message)

        response[:payload].find do |transaction|
          received_amount = transaction[:received] ? transaction[:received][invoice.address] : transaction[:amount]

          received_amount&.to_d == invoice.amount.to_d && Time.parse(transaction[:datetime]) > invoice.created_at
        end if response[:payload]
      end
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        currency = wallet.currency.to_s.downcase

        (SPECIFIC_CLIENTS[currency] || 'Client').constantize.new(api_key: api_key, currency: currency)
      end
    end
  end
end
