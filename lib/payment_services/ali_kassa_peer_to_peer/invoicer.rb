# frozen_string_literal: true

# Copyright (c) 2019 FINFEX https://github.com/finfex

require_relative 'invoice'


module PaymentServices
  class AliKassaPeerToPeer
    class Invoicer < ::PaymentServices::Base::Invoicer
      ALIKASSA_PAYMENT_FORM_URL = 'https://sci.alikassa.com/payment'
      ALIKASSA_RUB_CURRENCY = 'RUB'
      ALIKASSA_CARD = 'card'

      def create_invoice(money)
        Invoice.create!(amount: money, order_public_id: order.public_id)
      end

      def invoice_form_data
        pay_way = order.income_payment_system.payway&.capitalize

        invoice_params = {
          merchantUuid: order.income_wallet.merchant_id,
          orderId: order.public_id,
          amount: order.invoice_money.to_f,
          currency: ALIKASSA_RUB_CURRENCY,
          payWayVia: pay_way,
          desc: I18n.t('payment_systems.default_product', order_id: order.public_id),
          customerEmail: order.user.try(:email),
          urlSuccess: order.success_redirect,
          urlFail: order.failed_redirect
        }
        invoice_params[:payWayOn] = 'Qiwi' if pay_way == 'Qiwi'
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

      private

      def calculate_signature(params)
        sign_string = params.sort_by { |k, _v| k }.map(&:last).join(':')
        sign_string += ":#{api_key}"
        Digest::MD5.base64digest(sign_string)
      end
    end
  end
end
