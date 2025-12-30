# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

module PaymentServices
  class YourPayments
    class Invoicer < ::PaymentServices::Base::Invoicer
      PROVIDER_REQUISITES_FOUND_STATE = 'TRADER_ACCEPTED'
      PROVIDER_REQUEST_RETRIES = 3
      CARD_METHOD_TYPE = 'card_number'
      SBP_METHOD_TYPE  = 'phone_number'

      Error = Class.new StandardError

      def prepare_invoice_and_get_wallet!(currency:, token_network:)
        create_invoice!
        card_number, card_holder, bank_name = fetch_card_details!

        PaymentServices::Base::Wallet.new(address: card_number, name: card_holder, memo: bank_name)
      end

      def create_invoice(money)
        invoice
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        transaction = client.transaction(transaction_id: invoice.deposit_id)
        invoice.update_state_by_provider(transaction['status'])
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      def confirm_payment
        client.confirm_payment(deposit_id: invoice.deposit_id)
      end

      private

      delegate :card_bank, :sbp_bank, :sbp?, to: :resolver
      delegate :income_payment_system, :income_unk, to: :order
      delegate :currency, to: :income_payment_system

      def invoice_params
        {
          type: 'buy',
          amount: invoice.amount_cents,
          currency: currency.to_s,
          method_type: method_type,
          customer_id: order.user_id.to_s,
          invoice_id: order.public_id.to_s
        }
      end

      def create_invoice!
        Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
        response = client.create_provider_transaction(params: invoice_params)

        raise Error, "Can't create invoice: #{response}" unless response['order_id']
        invoice.update!(deposit_id: response['order_id'])
      end

      def fetch_card_details!
        status = request_trader
        raise Error, 'Нет доступных реквизитов для оплаты' unless status == PROVIDER_REQUISITES_FOUND_STATE

        payment_details = client.payment_details(invoice_id: invoice.deposit_id)
        number = payment_details['card']
        number = prepare_phone_number(number) if sbp?

        [number, payment_details['holder'], payment_details['bank']]
      end

      def request_trader
        PROVIDER_REQUEST_RETRIES.times do
          sleep 2

          params = { order_id: invoice.deposit_id }
          params[:bank] = sbp_bank if sbp? && sbp_bank.present?
          params[:bank] = card_bank unless sbp?
          status = client.request_payment_details(params: params)
          break status if status == PROVIDER_REQUISITES_FOUND_STATE
        end
      end

      def resolver
        @resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
      end

      def method_type
        sbp? ? SBP_METHOD_TYPE : CARD_METHOD_TYPE
      end

      def prepare_phone_number(provider_phone_number)
        "#{provider_phone_number[0..1]} (#{provider_phone_number[3..5]}) #{provider_phone_number[7..9]}-#{provider_phone_number[11..12]}-#{provider_phone_number[14..15]}"
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
