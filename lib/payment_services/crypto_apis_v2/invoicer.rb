# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::CryptoApisV2
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    ETC_TIME_THRESHOLD = 20.seconds
    PARTNERS_RECEIVED_AMOUNT_DELTA = 0.000001
    BASIC_TIME_COUNTDOWN = 1.minute
    FUNGIBLE_TOKENS = %w(usdt)

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.has_transaction! if invoice.pending?

      update_invoice_details(invoice: invoice, transaction: transaction)
      invoice.pay!(payload: transaction) if invoice.confirmed?
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def update_invoice_details(invoice:, transaction:)
      invoice.transaction_created_at ||= timestamp_in_utc(transaction['timestamp'] || transaction['transactionTimestamp'])
      invoice.transaction_id ||= transaction['transactionId'] || transaction['transactionHash']
      invoice.confirmed = transaction['isConfirmed'] if transaction['isConfirmed']
      invoice.save!
    end

    def transaction_for(invoice)
      if invoice.transaction_id
        client.transaction_details(invoice.transaction_id)['data']['item']
      else
        response = client.address_transactions(invoice.address)
        raise response['error']['message'] if response['error']

        response['data']['items'].find do |transaction|
          if fungible_token?
            match_token?(transaction)
          else
            match_transaction?(transaction)
          end
        end
      end
    end

    def match_transaction?(transaction)
      amount = parse_received_amount(transaction)
      transaction_created_at = timestamp_in_utc(transaction['timestamp'])
      invoice_created_at = expected_invoice_created_at
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      match_by_amount_and_time?(amount, time_diff) || match_by_txid_amount_and_time?(amount, transaction['transactionId'], time_diff)
    end

    def match_by_amount_and_time?(amount, time_diff)
      match_amount?(amount) && match_transaction_time_threshold?(time_diff)
    end

    def match_by_txid_amount_and_time?(amount, txid, time_diff)
      invoice.possible_transaction_id.present? &&
        match_txid?(txid) &&
        match_amount_with_delta?(amount) &&
        match_transaction_time_threshold?(time_diff)
    end

    def match_amount?(received_amount)
      received_amount.to_d == invoice.amount.to_d
    end

    def match_amount_with_delta?(received_amount)
      amount_diff = received_amount.to_d - invoice.amount.to_d
      amount_diff >= 0 && amount_diff <= PARTNERS_RECEIVED_AMOUNT_DELTA
    end

    def match_transaction_time_threshold?(time_diff)
      time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
    end

    def match_txid?(txid)
      txid == invoice.possible_transaction_id
    end

    def match_token?(transaction)
      amount = parse_received_tokens(transaction)
      transaction_created_at = timestamp_in_utc(transaction['transactionTimestamp'])
      invoice_created_at = expected_invoice_created_at
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      match_by_amount_and_time?(amount, time_diff) && match_by_contract_address?(transaction)
    end

    def match_by_contract_address?(transaction)
      transaction['contractAddress'] == order.income_wallet.payment_system.token_network
    end

    def parse_received_amount(transaction)
      transaction['recipients'].find { |recipient| recipient['address'].include?(invoice.address) }['amount']
    end

    def parse_received_tokens(transaction)
      if transaction['recipientAddress'] == invoice.address
        transaction['tokensAmount']
      else
        0
      end
    end

    def timestamp_in_utc(timestamp)
      DateTime.strptime(timestamp.to_s,'%s').utc
    end

    def expected_invoice_created_at
      invoice_created_at = invoice.created_at.utc
      invoice_created_at -= ETC_TIME_THRESHOLD if invoice.amount_currency == 'ETC'
      invoice_created_at
    end

    def fungible_token?
      @fungible_token ||= FUNGIBLE_TOKENS.include?(order.income_wallet.currency.to_s.downcase)
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
