# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'

class PaymentServices::AnyMoney
  class Invoicer < ::PaymentServices::Base::Invoicer
    ANYMONEY_PAYMENT_FORM_URL = 'https://sci.any.money/invoice'
    RUB_PAYWAYS = %w[qiwi]
    UAH_PAYWAYS = %w[visamc visamc_p2p]
    ANYMONEY_TIME_LIMIT = "1h30m"

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def invoice_form_data
      routes_helper = Rails.application.routes.url_helpers
      redirect_url = order.redirect_url.presence || routes_helper.public_payment_status_success_url(order_id: order.public_id)

      form_params = {
        merchant: order.income_wallet.merchant_id,
        externalid: order.public_id,
        amount: amount,
        in_curr: currency.to_s,
        expiry: ANYMONEY_TIME_LIMIT,
        payway: payway,
        callback_url: order.income_payment_system.callback_url,
        client_email: order.user&.email,
        merchant_payfee: order.income_payment_system.transfer_comission_payer_shop? ? "1" : "0",
        redirect_url: redirect_url
      }
      {
        url: ANYMONEY_PAYMENT_FORM_URL,
        method: 'POST',
        target: '_blank',
        'accept-charset' => 'UTF-8',
        inputs: form_params.merge(sign: build_signature(form_params))
      }
    end

    def build_signature(params)
      sign_string = params.sort_by { |k, _v| k }.map(&:last).join.downcase
      OpenSSL::HMAC.hexdigest('SHA512', order.income_wallet.api_key, sign_string)
    end

    private

    def payway
      @payway ||= order.income_payment_system.payway
    end

    def currency
      if RUB_PAYWAYS.include?(payway)
        RUB
      elsif UAH_PAYWAYS.include?(payway)
        UAH
      end
    end

    def amount
      if currency == RUB
        order.invoice_money
      elsif currency == UAH
        order.invoice_money.exchange_to(UAH)
      end.to_f.to_s
    end
  end
end
