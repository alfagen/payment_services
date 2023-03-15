# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  # Базовый класс Инвойсера. Сервис который выставляет счета
  #
  # Испошльзуется как описание интерфейса
  #
  class ::PaymentServices::Base::Invoicer
    include Virtus.model strict: true

    attribute :order # PaymentServices.configuration.preliminary_order_class

    def create_invoice(_money)
      raise "Method `create_invoice` is not implemented for class #{self.class}"
    end

    def invoice_form_data
      # not implemented and nil by default
      nil
    end

    def pay_invoice_url
      # not implemented and nil by default
      nil
    end

    def able_to_refund?
      false
    end

    def payments
      # not implemented and nil by default
      nil
    end

    def async_invoice_state_updater?
      false
    end

    private

    def api_keys
      @api_keys ||= begin
        class_name = self.class.name.delete_suffix('::Invoicer')
        PaymentServiceApiKey.find_by(payment_service_name: class_name) || raise("Ключи для #{class_name} не заведены")
      end
    end

    def api_key
      api_keys.income_api_key
    end

    def api_secret
      api_keys.income_api_secret
    end

    delegate :id, to: :order, prefix: true

    # AdvCash:
    # ac_status_url: "#{routes_helper.public_public_callbacks_api_root_url}/v1/adv_cash/receive_payment",
    # ac_success_url: routes_helper.public_payment_status_success_url(order_id: order.public_id),
    # ac_fail_url: routes_helper.public_payment_status_fail_url(order_id: order.public_id),
    #
    def routes_helper
      Rails.application.routes.url_helpers
    end
  end
end
