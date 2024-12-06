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
  require 'payment_services/base/crypto_payout'
  require 'payment_services/base/fiat_invoice'
  require 'payment_services/base/fiat_payout'
  require 'payment_services/base/wallet'
  require 'payment_services/base/p2p_bank_resolver'

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
  autoload :AnyPay, 'payment_services/any_pay'
  autoload :MerchantAlikassa, 'payment_services/merchant_alikassa'
  autoload :CoinPaymentsHub, 'payment_services/coin_payments_hub'
  autoload :PayForU, 'payment_services/pay_for_u'
  autoload :BestApi, 'payment_services/best_api'
  autoload :PayForUH2h, 'payment_services/pay_for_u_h2h'
  autoload :PaylamaSbp, 'payment_services/paylama_sbp'
  autoload :PaylamaP2p, 'payment_services/paylama_p2p'
  autoload :XPayPro, 'payment_services/x_pay_pro'
  autoload :Wallex, 'payment_services/wallex'
  autoload :Tronscan, 'payment_services/tronscan'
  autoload :YourPayments, 'payment_services/your_payments'
  autoload :Bridgex, 'payment_services/bridgex'
  autoload :JustPays, 'payment_services/just_pays'
  autoload :Transfera, 'payment_services/transfera'
  autoload :Cryptomus, 'payment_services/cryptomus'
  autoload :Paycraft, 'payment_services/paycraft'
  autoload :Bovapay, 'payment_services/bovapay'
  autoload :Erapay, 'payment_services/erapay'
  autoload :MerchantAlikassaVirtual, 'payment_services/merchant_alikassa_virtual'
  autoload :PaycraftVirtual, 'payment_services/paycraft_virtual'
  autoload :XPayProVirtual, 'payment_services/x_pay_pro_virtual'
  autoload :PayFinity, 'payment_services/pay_finity'

  UnauthorizedPayout = Class.new StandardError

  def self.configure
    @configuration = Configuration.new
    yield(configuration)
  end
end
