# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

module PaymentServices
  class MerchantAlikassaVirtual
    class Invoicer < ::PaymentServices::Base::Invoicer
      DEFAULT_USER_AGENT = 'Chrome/47.0.2526.111'
      SERVICE = 'virtual_account_rub_hpp'

      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id)
        response = client.create_invoice(params: invoice_params)
        raise response['message'] if response['errors']

        invoice.update!(
          deposit_id: response['id'],
          pay_url: response['url']
        )
      end

      def pay_invoice_url
        invoice.reload.pay_url if invoice
      end

      def async_invoice_state_updater?
        true
      end

      def update_invoice_state!
        transaction = client.invoice_transaction(deposit_id: invoice.deposit_id)
        invoice.update_state_by_provider(transaction['payment_status'])
      end

      def invoice
        @invoice ||= Invoice.find_by(order_public_id: order.public_id)
      end

      private

      def invoice_params
        {
          amount: invoice.amount.to_i,
          order_id: order.public_id.to_s,
          service: SERVICE,
          customer_ip: order.remote_ip,
          customer_user_id: "#{Rails.env}_user_id_#{order.user_id}"
        }
      end

      def client
        @client ||= Client.new(api_key: api_key, secret_key: api_secret)
      end
    end
  end
end
