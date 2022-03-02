# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MasterProcessing
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      CARD_NUMBER_FOR_QIWI_PAYWAY = '9999'
      CARD_PAYWAY = 'visamc'
      QIWI_PAYWAY = 'qiwi'
      CARD_PAYWAY_OPTION = 'card'
      QIWI_PAYWAY_OPTION = 'qw'

      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        amount: invoice.amount.to_i,
        expireAt: PreliminaryOrder::MAX_LIVE.to_i,
        callbackURL: "#{order.income_payment_system.callback_url}/#{order.public_id}",
        comment: comment,
        clientIP: client_ip,
        paySourcesFilter: pay_source,
        cardNumber: card_number,
        email: order.email
      }

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

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      response = client.invoice_status(params: { externalID: invoice.reload.deposit_id })
      raise "Can't get withdrawal details" unless response['statusName']

      invoice.update_state_by_provider(response['statusName'])
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
      order.user.last_login_from_ip_address || ""
    end

    def payway
      @payway ||= order.income_payment_system.payway
    end

    def pay_source
      available_options = {
        CARD_PAYWAY   => CARD_PAYWAY_OPTION,
        QIWI_PAYWAY   => QIWI_PAYWAY_OPTION
      }
      available_options[payway]
    end

    def card_number
      available_options = {
        CARD_PAYWAY   => the_last_four_card_number,
        QIWI_PAYWAY   => CARD_NUMBER_FOR_QIWI_PAYWAY
      }
      available_options[payway]
    end

    def the_last_four_card_number
      order.income_account.last(4)
    end
  end
end
