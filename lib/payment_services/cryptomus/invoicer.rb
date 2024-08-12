# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::Cryptomus
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    USDT_NETWORK_TO_CURRENCY = {
      'trc20' => 'TRON',
      'erc20' => 'ETH',
      'ton'   => 'TON',
      'sol'   => 'SOL',
      'POLYGON' => 'POLYGON',
      'bep20' => 'BSC'
    }.freeze

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = client.create_invoice(params: invoice_params)
      raise Error, "Can't create invoice: #{response['message']}" if response['message']

      invoice.update!(deposit_id: response.dig('result', 'uuid'))
      PaymentServices::Base::Wallet.new(
        address: response.dig('result', 'address'),
        name: nil
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.invoice(params: { uuid: invoice.deposit_id })

      invoice.update(transaction_id: transaction.dig('result', 'txid'))
      if valid_transaction?(transaction)
        transfer_to_personal(transaction) if income_to_personal_account
        invoice.update_state_by_provider(transaction.dig('result', 'payment_status'))
      end
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :token_network, :income_to_personal_account, to: :income_payment_system
    delegate :income_payment_system, to: :order

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      currency = invoice.amount_currency.to_s.downcase.inquiry
      currency = 'dash'.inquiry if currency.dsh?
      params = {
        amount: invoice.amount.to_f.to_s,
        currency: currency.upcase,
        order_id: order.public_id.to_s,
        lifetime: order.income_payment_timeout.to_i
      }
      params[:network] = currency.usdt? || currency.bnb? ? network(currency) : currency.upcase
      params
    end

    def transfer_to_personal(transaction)
      status = transaction.dig('result', 'payment_status')
      return unless status.in?(Invoice::SUCCESS_PROVIDER_STATES)

      amount_in_usdt = transaction.dig('result', 'convert', 'amount')
      response = client.transfer_to_personal(amount: amount_in_usdt, signature_key: api_keys.outcome_api_secret)
      order.append_comment(response['message']) if response['message'].present?
    end

    def network(currency)
      return 'BSC' if currency.bnb?

      USDT_NETWORK_TO_CURRENCY[token_network] || 'USDT'
    end

    def valid_transaction?(transaction)
      amount = transaction.dig('result', 'payment_amount')
      amount.nil? || amount.to_f == invoice.amount.to_f
    end

    def client
      @client ||= Client.new(api_key: api_key, secret_key: api_secret)
    end
  end
end
