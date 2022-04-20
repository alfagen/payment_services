# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Blockchair
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    ETC_TIME_THRESHOLD = 20.seconds
    BASIC_TIME_COUNTDOWN = 1.minute
    AMOUNT_DIVIDER = 1e+8
    ETH_AMOUNT_DIVIDER = 1e+18
    CARDANO_AMOUNT_DIVIDER = 1e+6
    TRANSANSACTIONS_AMOUNT_TO_CHECK = 3

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.has_transaction! if invoice.pending?

      update_invoice_details(invoice: invoice, transaction: transaction)
      invoice.pay!(payload: transaction) if transaction_added_to_block?(transaction) || transaction['transaction_successful']
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def update_invoice_details(invoice:, transaction:)
      if blockchain.blockchain.cardano?
        invoice.transaction_created_at ||= timestamp_in_utc(transaction['ctbTimeIssued'])
        invoice.transaction_id ||= transaction['ctbId']
      elsif blockchain.blockchain.stellar?
        invoice.transaction_created_at ||= DateTime.parse(transaction['created_at']).utc
        invoice.transaction_id ||= transaction['transaction_hash']
      else
        invoice.transaction_created_at ||= datetime_string_in_utc(transaction['time'])
        invoice.transaction_id ||= transaction['transaction_hash']
      end

      invoice.save!
    end

    def transaction_for(invoice)
      if blockchain.blockchain.ethereum?
        client.transaction_ids(address: invoice.address)['data'][invoice.address]['calls'].find do |transaction|
          match_transaction?(transaction)
        end
      elsif blockchain.blockchain.monero?
        match_transaction?(transaction)
      elsif blockchain.blockchain.cardano?
        client.transaction_ids(address: invoice.address)['data'][invoice.address]['address']['caTxList'].find do |transaction|
          match_cardano_transaction?(transaction)
        end
      elsif blockchain.blockchain.stellar?
        memo = order.income_wallet.name
        transactions = client.stellar_transactions(address: invoice.address)['data'][invoice.address]['transactions']
        tx = transactions.find { |transaction| transaction['memo'] == order.income_wallet.name }
        return false unless tx

        txid = tx['hash']
        client.transaction_ids(address: invoice.address)['data'][invoice.address]['payments'].find do |transaction|
          match_stellar_transaction?(transaction, txid)
        end
      else
        transactions_outputs(transactions_data_for(invoice)).find do |transaction|
          match_transaction?(transaction)
        end
      end
    end

    def match_stellar_transaction?(transaction, txid)
      return false unless transaction['transaction_hash'] == txid
      return false unless transaction['type'] == 'payment'

      transaction_created_at = DateTime.parse(transaction['created_at']).utc
      invoice_created_at = invoice.created_at.utc
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      match_by_amount_and_time?(transaction['amount'], time_diff)
    end

    def match_cardano_transaction?(transaction)
      transaction_created_at = timestamp_in_utc(transaction['ctbTimeIssued'])
      invoice_created_at = invoice.created_at.utc
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / BASIC_TIME_COUNTDOWN
      transaction['ctbOutputs'].each do |output|
        return true if match_by_output_and_time?(output, time_diff)
      end

      false
    end

    def match_by_output_and_time?(output, time_diff)
      amount = output['ctaAmount']['getCoin'].to_f / amount_divider
      match_by_amount_and_time?(amount, time_diff) && output['ctaAddress'] == invoice.address
    end

    def match_transaction?(transaction)
      amount = transaction['value'].to_f / amount_divider
      transaction_created_at = datetime_string_in_utc(transaction['time'])
      invoice_created_at = invoice.created_at.utc
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

    def timestamp_in_utc(timestamp)
      Time.at(timestamp).to_datetime.utc
    end

    def transaction_added_to_block?(transaction)
      transaction.key?('block_id') ? transaction['block_id'] > 0 : true
    end

    def transactions_data_for(invoice)
      transaction_ids_on_wallet = client.transaction_ids(address: invoice.address)['data'][invoice.address]['transactions']
      client.transactions_data(tx_ids: transaction_ids_on_wallet.first(TRANSANSACTIONS_AMOUNT_TO_CHECK))['data']
    end

    def transactions_outputs(transactions_data)
      outputs = []

      transactions_data.each do |_transaction_id, transaction|
        outputs << transaction['outputs']
      end

      outputs.flatten
    end

    def blockchain
      @blockchain ||= Blockchain.new(currency: order.income_wallet.currency.to_s.downcase)
    end

    def amount_divider
      if blockchain.blockchain.ethereum?
        ETH_AMOUNT_DIVIDER
      elsif blockchain.blockchain.cardano?
        CARDANO_AMOUNT_DIVIDER
      else
        AMOUNT_DIVIDER
      end
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
