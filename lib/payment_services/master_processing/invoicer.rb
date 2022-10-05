# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MasterProcessing
  class Invoicer < ::PaymentServices::Base::Invoicer
    QIWI_DUMMY_CARD_TAIL = '9999'
    AVAILABLE_PAYSOURCE_OPTIONS = {
      'visamc'  => 'card',
      'cardh2h' => 'card',
      'qiwi'    => 'qw',
      'qiwih2h' => 'qw'
    }

    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        amount: invoice.amount.to_i,
        expireAt: PreliminaryOrder::MAX_LIVE.to_i,
        comment: comment,
        clientIP: client_ip,
        paySourcesFilter: pay_source,
        cardNumber: the_last_four_card_number,
        email: order.email
      }

      raw_response = client.create_invoice(params: params, payway: payway)
      response = Response.build_from(raw_response: raw_response)

      raise "Can't create invoice: #{response.error_message}" unless response.success?

      invoice.update!(
        deposit_id: response.deposit_id,
        pay_invoice_url: response.pay_invoice_url
      )
    end

    def pay_invoice_url
      invoice.reload.pay_invoice_url if invoice
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
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
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
      order.remote_ip || ""
    end

    def payway
      @payway ||= order.income_payment_system.payway.inquiry
    end

    def pay_source
      AVAILABLE_PAYSOURCE_OPTIONS[payway]
    end

    def the_last_four_card_number
      return QIWI_DUMMY_CARD_TAIL if payway_qiwi?

      order.income_account.last(4)
    end

    def payway_qiwi?
      payway.qiwi? || payway.qiwih2h?
    end
  end
end
