# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'invoice'

class PaymentServices::AdvCash
  class Invoicer < ::PaymentServices::Base::Invoicer
    ADV_CASH_URL = 'https://wallet.advcash.com/sci/'

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id)
    end

    def invoice_form_data # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      routes_helper = Rails.application.routes.url_helpers
      invoice = Invoice.find_by!(order_public_id: order.public_id)
      redirect_url = order.redirect_url.presence || routes_helper.public_payment_status_success_url(order_id: order.public_id)

      form_data = {
        email: order.income_wallet.adv_cash_merchant_email.presence ||
               raise("Не установлено поле adv_cash_merchant_email у кошелька #{order.income_wallet.id}"),
        shop_name: order.income_wallet.merchant_id.presence ||
                   raise("Не установлено поле merchant_id у кошелька #{order.income_wallet.id}"),
        amount: invoice.formatted_amount,
        currency: invoice.amount.currency.to_s,
        order_id: invoice.order_public_id
      }

      sign_array = [
        form_data[:email],
        form_data[:shop_name],
        form_data[:amount],
        form_data[:currency],
        order.income_wallet.api_key,
        form_data[:order_id]
      ]
      signature = Digest::SHA256.hexdigest(sign_array.join(':'))

      {
        url: ADV_CASH_URL,
        method: 'post',
        inputs: {
          ac_account_email: form_data[:email],
          ac_sci_name: form_data[:shop_name],
          ac_order_id: form_data[:order_id],
          ac_sign: signature,
          ac_status_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/adv_cash/receive_payment",
          ac_success_url: redirect_url,
          ac_success_method: 'get',
          ac_fail_url: routes_helper.public_payment_status_fail_url(order_id: order.public_id),
          ac_fail_method: 'get',
          ac_status_url_method: 'post',
          ac_amount: form_data[:amount],
          ac_currency: form_data[:currency],
          ac_comments: I18n.t('payment_systems.default_product', order_id: order.public_id)
        }
      }
    end
  end
end
