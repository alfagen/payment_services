# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class YandexMoney < Base
    autoload :Invoice, 'payment_services/yandex_money/invoice'
    autoload :Invoicer, 'payment_services/yandex_money/invoicer'

    register :invoicer, Invoicer
  end
end
