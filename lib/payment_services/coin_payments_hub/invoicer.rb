# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'
require_relative 'transaction'
require_relative 'currency_repository'

module PaymentServices
  class CoinPaymentsHub
    class Invoicer < ::PaymentServices::Base::Invoicer
      PROVIDER_SUCCESS_STATE = 'ok'
      Error = Class.new StandardError

      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id)
        response = client.create_invoice(params: invoice_params)
        validate_response!(response)

        create_temp_kassa_wallet(address: response.dig('result', 'address'))
        invoice.update!(deposit_id: order.public_id.to_s)
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        response = client.transaction(deposit_id: invoice.deposit_id)
        validate_response!(response)

        raw_transaction = response['result']
        transaction = Transaction.build_from(raw_transaction)
        invoice.update_state_by_transaction!(transaction)
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      delegate :income_payment_system, to: :order
      delegate :withdrawal_wallet, to: :income_payment_system
      delegate :token_network, to: :income_payment_system
      delegate :wallets, to: :income_payment_system

      def invoice_params
        {
          amount: invoice.amount.to_f,
          network: CurrencyRepository.build_from(token_network: token_network).provider_network,
          token: CurrencyRepository.build_from(token_network: token_network).provider_token,
          withdrawal_wallet: withdrawal_wallet,
          order_id: order.public_id.to_s,
          ttl: PreliminaryOrder::MAX_LIVE.to_i,
          is_client_repeat_wallet: false
        }
      end

      def create_temp_kassa_wallet(address:)
        wallet = wallets.find_or_create_by(account: address)
        order.update(income_wallet_id: wallet.id)
      end

      def validate_response!(response)
        return if response['state'] == PROVIDER_SUCCESS_STATE
    
        raise Error, "Can't create invoice: #{response.dig('result', 'error')}" 
      end

      def client
        @client ||= Client.new(api_key: api_key)
      end
    end
  end
end
