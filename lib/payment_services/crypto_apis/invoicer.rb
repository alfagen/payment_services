# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'client'

class PaymentServices::CryptoApis
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    ETC_TIME_THRESHOLD = 20.seconds
    PARTNERS_RECEIVED_AMOUNT_DELTA = 0.000001

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.has_transaction! if invoice.pending?

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
          received_amount = transaction[:amount]
          received_amount = transaction[:received][invoice.address] unless transaction[:received][invoice.address] == invoice.address 

          transaction_created_at = DateTime.strptime(transaction[:timestamp].to_s,'%s').utc
          invoice_created_at = expected_invoice_created_at

          next if invoice_created_at >= transaction_created_at

          time_diff = (transaction_created_at - invoice_created_at) / 1.minute

          match_received_amount(received_amount) && match_transaction_time_threshold(time_diff) ||
          invoice.possible_transaction_id.present? && match_txid(transaction[:txid]) && match_received_amount_with_delta(received_amount) && match_transaction_time_threshold(time_diff)
        end if response[:payload]
      end
    end

    def expected_invoice_created_at
      invoice_created_at = invoice.created_at.utc
      invoice_created_at -= ETC_TIME_THRESHOLD if invoice.amount_currency == 'ETC'
      invoice_created_at
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        currency = wallet.currency.to_s.downcase

        Client.new(currency: currency).invoice.new(api_key: api_key, currency: currency)
      end
    end

    def match_received_amount(received_amount)
      received_amount.to_d == invoice.amount.to_d
    end

    def match_received_amount_with_delta(received_amount)
      amount_diff = received_amount.to_d - invoice.amount.to_d
      amount_diff >= 0 && amount_diff <= PARTNERS_RECEIVED_AMOUNT_DELTA
    end

    def match_transaction_time_threshold(time_diff)
      time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
    end

    def match_txid(txid)
      txid == invoice.possible_transaction_id
    end
  end
end
