# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require 'payment_services/version'
require 'payment_services/configuration'

module PaymentServices
  class << self
    attr_reader :configuration
  end

  require 'payment_services/base'
  require 'payment_services/base/invoicer'
  require 'payment_services/base/payout_adapter'

  autoload :QIWI, 'payment_services/qiwi'
  autoload :AdvCash, 'payment_services/adv_cash'
  autoload :Payeer, 'payment_services/payeer'
  autoload :PerfectMoney, 'payment_services/perfect_money'
  autoload :RBK, 'payment_services/rbk'
  autoload :YandexMoney, 'payment_services/yandex_money'
  autoload :BlockIo, 'payment_services/block_io'
  autoload :CryptoApis, 'payment_services/crypto_apis'
  autoload :AnyMoney, 'payment_services/any_money'
  autoload :AppexMoney, 'payment_services/appex_money'
  autoload :Kuna, 'payment_services/kuna'

  UnauthorizedPayout = Class.new StandardError

  def self.configure
    @configuration = Configuration.new
    yield(configuration)
  end
end
