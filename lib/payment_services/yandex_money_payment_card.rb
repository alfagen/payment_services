# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class YandexMoneyPaymentCard < Base
    autoload :Invoice, 'payment_services/yandex_money_payment_card/invoice'
    autoload :Invoicer, 'payment_services/yandex_money_payment_card/invoicer'

    register :invoicer, Invoicer
  end
end
