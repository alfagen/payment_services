# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Blockchair
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    ETC_TIME_THRESHOLD = 20.seconds
    BASIC_TIME_COUNTDOWN = 1.minute
    VALUE_DIVIDER = 1e+8

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.has_transaction! if invoice.pending?

      update_invoice_details(invoice: invoice, transaction: transaction)
      invoice.pay!(payload: transaction)
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def update_invoice_details(invoice:, transaction:)
      invoice.transaction_created_at = datetime_string_in_utc(transaction['time'])
      invoice.transaction_id = transaction['transaction_hash']
      invoice.save!
    end

    def transaction_for(invoice)
      transaction_ids = client.transaction_ids(address: invoice.address)['data'][invoice.address]['transactions']
      transactions_information = client.transactions_information(tx_ids: transaction_ids.first(5))['data']
      transactions = []

      transactions_information.each do |_transaction_id, transactions_information|
        transactions << transactions_information['outputs']
      end

      transactions.flatten.find do |transaction|
        match_transaction?(transaction)
      end
    end

    def match_transaction?(transaction)
      amount = transaction['value'].to_f / VALUE_DIVIDER
      transaction_created_at = datetime_string_in_utc(transaction['time'])
      invoice_created_at = expected_invoice_created_at
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      match_by_amount_and_time?(amount, time_diff)
    end

    def match_by_amount_and_time?(amount, time_diff)
      match_amount?(amount) && match_transaction_time_threshold?(time_diff)
    end

    def match_amount?(received_amount)
      received_amount.to_d == invoice.amount.to_d
    end

    def match_transaction_time_threshold?(time_diff)
      time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
    end

    def datetime_string_in_utc(datetime_string)
      DateTime.parse(datetime_string).utc
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

        Client.new(api_key: api_key, currency: currency)
      end
    end
  end
end
