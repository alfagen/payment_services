# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'

class PaymentServices::PerfectMoney
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def invoice_form_data
      invoice = Invoice.find_by!(order_public_id: order.public_id)
      routes_helper = Rails.application.routes.url_helpers
      redirect_url = order.redirect_url.presence || routes_helper.public_payment_status_success_url(order_id: order.public_id)

      {
        url: 'https://perfectmoney.is/api/step1.asp',
        method: 'POST',
        inputs: {
          PAYEE_ACCOUNT: order.income_wallet.account,
          PAYEE_NAME: RestageUrlHelper::ORIGINAL_HOME_URL,
          PAYMENT_ID: order.public_id,
          PAYMENT_AMOUNT: format('%.2f', invoice.amount.to_f),
          PAYMENT_UNITS: invoice.amount.currency.to_s,
          STATUS_URL: "#{routes_helper.public_public_callbacks_api_root_url}/v1/perfect_money/receive_payment",
          PAYMENT_URL: redirect_url,
          PAYMENT_URL_METHOD: 'GET',
          NOPAYMENT_URL: routes_helper.public_payment_status_fail_url(order_id: order.public_id),
          NOPAYMENT_URL_METHOD: 'GET',
          SUGGESTED_MEMO: I18n.t('payment_systems.default_product', order_id: order.public_id),
          BAGGAGE_FIELDS: '',
          PAYMENT_METHOD: ''
        }
      }
    end
  end
end
