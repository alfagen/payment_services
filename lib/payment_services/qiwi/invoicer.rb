# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'

class PaymentServices::QIWI
  class Invoicer < ::PaymentServices::Base::Invoicer
    QIWI_PAYMENT_FORM_URL = 'https://qiwi.com/payment/form'
    # https://developer.qiwi.com/ru/qiwi-wallet-personal/index.html#payform
    # перевод на виртуальную карту киви
    QIWI_PROVIDER = 22_351
    QIWI_CURRENCY_RUB = 643

    def create_invoice(money); end

    def pay_invoice_url
      uri = URI.parse("#{QIWI_PAYMENT_FORM_URL}/#{QIWI_PROVIDER}")
      routes_helper = Rails.application.routes.url_helpers
      redirect_url = order.redirect_url.presence || routes_helper.public_payment_status_success_url(order_id: order.public_id)
      income_money = order.income_money
      whole_amount, fractional_amount = income_money.fractional.abs.divmod(income_money.currency.subunit_to_unit)
      uri.query = {
        amountInteger: whole_amount,
        amountFraction: fractional_amount,
        currency: QIWI_CURRENCY_RUB,
        urlSuccess: redirect_url,
        "extra['comment']" => I18n.t('payment_systems.default_product', order_id: order.public_id),
        "extra['account']" => order.income_wallet.account
      }.to_query

      uri
    end
  end
end
