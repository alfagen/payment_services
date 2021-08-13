# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Exmo
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    WalletOperationsRequestFailed = Class.new StandardError

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.wallet_operations(currency: invoice.amount_currency, type: 'deposit')
      raise WalletOperationsRequestFailed, "Can't get wallet operations" unless response['items']

      transaction = find_transaction(transactions: response['items'])
      return if transaction.nil?

      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def find_transaction(transactions:)
      transactions.find do |transaction|
        transaction_created_at = DateTime.strptime(transaction[:created].to_s,'%s').utc
        invoice_created_at = invoice.created_at.utc
        next if invoice_created_at >= transaction_created_at

        time_diff = (transaction_created_at - invoice_created_at) / 1.minute
        transaction['amount'] == invoice.amount.to_d && time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
      end
    end
  
    def client
      @client ||= begin
        wallet = order.income_wallet
        Client.new(public_key: wallet.api_key, secret_key: wallet.api_secret)
      end
    end
  end
end
