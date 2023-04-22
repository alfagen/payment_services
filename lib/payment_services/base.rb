# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  # Базовый класс для платежного сервиса. Описывает подсервисы и хранит конфигурацию
  #
  class Base
    SUBSERVICES = %i[invoicer importer payout_adapter client fiat_invoice fiat_payout].freeze

    # Реестр подсервисов
    class Registry
      attr_accessor(*SUBSERVICES)
    end

    class << self
      delegate(*SUBSERVICES, to: :registry)

      def register(type, subservice_class)
        raise "Unknown type #{type}" unless SUBSERVICES.include? type
        raise 'must be a class' unless subservice_class.is_a? Class

        registry.send type.to_s + '=', subservice_class
      end

      def registry
        @registry ||= Registry.new
      end

      def payout_contains_fee?
        false
      end
    end
  end
end
