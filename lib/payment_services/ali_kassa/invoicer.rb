# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'
require_relative 'client'

class PaymentServices::AliKassa
  class Invoicer < ::PaymentServices::Base::Invoicer
    ALIKASSA_PAYMENT_FORM_URL = 'https://sci.alikassa.com/payment'
    ALIKASSA_TIME_LIMIT = 18.minute.to_i
    ALIKASSA_LOCALHOST_IP = '127.0.0.1'
    ALIKASSA_CARD = 'card'
    ALIKASSA_PRIVAT = 'privat24'

    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)
      # client = PaymentServices::AliKassa::Client.new(
      #   merchant_id: order.income_wallet.merchant_id,
      #   secret: order.income_wallet.api_key
      # )
      # deposit = client.create_deposit(
      #   amount: order.invoice_money.to_f,
      #   public_id: order.public_id,
      #   payment_system: order.income_payment_system.payway&.capitalize,
      #   currency: invoice.amount_currency,
      #   ip: ip_from(order),
      #   phone: order.income_account
      # )
      # invoice.update!(deposit_payload: deposit, pay_url: deposit.dig('return', 'payData', 'url'))
      invoice
    end

    def invoice_form_data
      invoice_params = {
        merchantUuid: order.income_wallet.merchant_id,
        orderId: order.public_id,
        amount: order.invoice_money.to_f,
        currency: order.income_money.currency.to_s,
        desc: I18n.t('payment_systems.default_product', order_id: order.public_id),
        lifetime: ALIKASSA_TIME_LIMIT,
        payWayVia: 'AliKassa',
        payWayOn: order.income_payment_system.payway&.capitalize,
        customerEmail: order.user.try(:email)
      }
      invoice_params[:number] = order.income_account.gsub(/\D/, '') if order.income_payment_system.payway == ALIKASSA_CARD
      invoice_params[:sign] = calculate_signature(invoice_params)

      {
        url: ALIKASSA_PAYMENT_FORM_URL,
        method: 'POST',
        target: '_blank',
        'accept-charset' => 'UTF-8',
        inputs: invoice_params
      }
    end

    def pay_invoice_url
      Invoice.find_by(order_public_id: order.public_id)&.pay_url
    end

    private

    def calculate_signature(params)
      sign_string = params.sort_by { |k, _v| k }.map(&:last).join(':')
      sign_string += ":#{order.income_wallet.api_key}"
      Digest::MD5.base64digest(sign_string)
    end

    def ip_from(user)
      if order.remote_ip.present?
        order.remote_ip
      elsif user.last_login_from_ip_address.present?
        order.user.last_login_from_ip_address
      elsif user.last_ip.present?
        order.user.last_ip
      else
        ALIKASSA_LOCALHOST_IP
      end
    end
  end
end
