# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MasterProcessing
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        amount: invoice.amount.to_i,
        expireAt: PreliminaryOrder::MAX_LIVE.to_i,
        callbackURL: order.income_payment_system.callback_url,
        comment: comment,
        clientIP: client_ip,
        paySourcesFilter: pay_source,
        cardNumber: card_number,
        email: order.email
      }
      params[:hsid] = generate_hsid(params)

      response = client.create_invoice(params: params)

      raise "Can't create invoice: #{response['cause']}" unless response['success']

      invoice.update!(
        deposit_id: response['billID'],
        pay_invoice_url: response['paymentLinks'].first
      )
    end

    def pay_invoice_url
      invoice.reload.pay_invoice_url
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def client
      @client ||= begin
        wallet = order.income_wallet

        Client.new(api_key: wallet.api_key, secret_key: wallet.api_secret)
      end
    end

    def comment
      "Order: #{order.public_id}"
    end

    def client_ip
      order.user.last_login_from_ip_address
    end

    def payway
      @payway ||= order.income_wallet.payment_system.payway
    end

    def pay_source
      available_options = {
        'visamc' => 'card',
        'qiwi'   => 'qw'
      }
      available_options[payway]
    end

    def card_number
      available_options = {
        'visamc' => order.income_account,
        'qiwi'   => '9999'
      }
      available_options[payway]
    end
  end
end
