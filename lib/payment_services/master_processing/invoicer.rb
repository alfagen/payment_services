# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::MasterProcessing
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        amount: invoice.amount.to_i,
        expireAt: expire_at,
        callbackURL: order.income_payment_system.callback_url
      }

      response = client.create_invoice(params: params)

      raise "Can't create invoice: #{response['cause']}" unless response['success']

      invoice.update!(
        deposit_id: response['externalID'],
        pay_invoice_url: response['walletList'].first
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

    def expire_at
      Time.now.to_i + PreliminaryOrder::MAX_LIVE.to_i
    end
  end
end
