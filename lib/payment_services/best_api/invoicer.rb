# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

module PaymentServices
  class BestApi
    class Invoicer < ::PaymentServices::Base::Invoicer
      def prepare_invoice_and_get_wallet!(currency:, token_network:)
        create_invoice!
        response = client.income_wallet(amount: order.calculated_income_money.to_i, currency: currency.to_s)

        invoice.update!(deposit_id: response['trade'])
        PaymentServices::Base::Wallet.new(address: prepare_card_number(response['card_number']), name: nil, name_group: response['trade'])
      end

      def create_invoice(money)
        invoice
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      def create_invoice!
        Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
      end

      def client
        @client ||= Client.new(api_key: api_key)
      end

      def prepare_card_number(provider_card_number)
        provider_card_number.split('|').first.split(' ').last
      end
    end
  end
end
