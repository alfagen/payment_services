# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Binance
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    WalletDepositsRequestFailed = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.deposit_history(currency: invoice.amount_currency)
      raise DepositHistoryRequestFailed, "Can't get deposit history: #{response['msg']}" if response.is_a? Hash

      transaction = find_transaction(transactions: response)
      return if transaction.nil?

      update_invoice_details(transaction: transaction)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    def update_invoice_details(transaction:)
      invoice.transaction_id ||= transaction['txId']
      invoice.transaction_created_at ||= parse_datetime_utc(transaction['insertTime'])
      invoice.save!
    end

    def parse_datetime_utc(timestamp_milliseconds)
      DateTime.strptime((timestamp_milliseconds / 1000).to_i.to_s,'%s').utc
    end

    def find_transaction(transactions:)
      transactions.find { |transaction| matches_amount_and_timing?(transaction) }
    end

    def matches_amount_and_timing?(transaction)
      transaction['amount'].to_d == invoice.amount.to_d && match_time_interval?(transaction)
    end

    def match_time_interval?(transaction)
      transaction_created_at_utc = parse_datetime_utc(transaction['insertTime'])
      invoice_created_at_utc = invoice.created_at.utc

      invoice_created_at_utc < transaction_created_at_utc && created_in_valid_interval?(transaction_created_at_utc, invoice_created_at_utc)
    end

    def created_in_valid_interval?(transaction_time, invoice_time)
      interval = (transaction_time - invoice_time)
      interval_in_minutes = (interval / 1.minute).round.minutes
      interval_in_minutes < TRANSACTION_TIME_THRESHOLD
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        Client.new(api_key: wallet.api_key, secret_key: wallet.api_secret)
      end
    end
  end
end
