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
  require 'payment_services/base/client'
  require 'payment_services/base/crypto_invoice'
  require 'payment_services/base/fiat_invoice'
  require 'payment_services/base/fiat_payout'
  require 'payment_services/base/wallet'

  autoload :QIWI, 'payment_services/qiwi'
  autoload :AdvCash, 'payment_services/adv_cash'
  autoload :Payeer, 'payment_services/payeer'
  autoload :PerfectMoney, 'payment_services/perfect_money'
  autoload :Rbk, 'payment_services/rbk'
  autoload :YandexMoney, 'payment_services/yandex_money'
  autoload :BlockIo, 'payment_services/block_io'
  autoload :CryptoApis, 'payment_services/crypto_apis'
  autoload :AnyMoney, 'payment_services/any_money'
  autoload :AppexMoney, 'payment_services/appex_money'
  autoload :Kuna, 'payment_services/kuna'
  autoload :Liquid, 'payment_services/liquid'
  autoload :Obmenka, 'payment_services/obmenka'
  autoload :Exmo, 'payment_services/exmo'
  autoload :Binance, 'payment_services/binance'
  autoload :MasterProcessing, 'payment_services/master_processing'
  autoload :CryptoApisV2, 'payment_services/crypto_apis_v2'
  autoload :Blockchair, 'payment_services/blockchair'
  autoload :OkoOtc, 'payment_services/oko_otc'
  autoload :Paylama, 'payment_services/paylama'
  autoload :PaylamaCrypto, 'payment_services/paylama_crypto'
  autoload :ExPay, 'payment_services/ex_pay'
  autoload :OneCrypto, 'payment_services/one_crypto'

  UnauthorizedPayout = Class.new StandardError

  def self.configure
    @configuration = Configuration.new
    yield(configuration)
  end
end
