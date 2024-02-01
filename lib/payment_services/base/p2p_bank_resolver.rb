# frozen_string_literal: true

class PaymentServices::Base
  class P2pBankResolver
    include Virtus.model

    attribute :adapter
    attribute :direction

    PAYWAY_TO_PROVIDER_BANK = {
      'PayForUH2h' => {
        'uah' => {
          '' => 'anyuabank'
        },
        'rub' => {
          'sberbank' => 'sberbank',
          'tinkoff'  => 'tinkoff',
          ''         => 'sberbank'
        },
        'uzs' => {
          'humo' => 'humo',
          ''     => 'uzcard'
        },
        'azn' => {
          'leo' => 'leobank',
          'uni' => 'unibank',
          ''    => 'yapikredi'
        }
      },
      'PaylamaP2p' => {
        'rub' => {
          'sberbank' => 'sberbank',
          'tinkoff'  => 'tinkoff',
          ''         => 'sberbank'
        },
        'uzs' => {
          'humo' => 'humo',
          ''     => 'visa/mc'
        },
        'azn' => {
          'leo' => 'leobank',
          'uni' => 'unibank',
          ''    => 'visa/mc'
        }
      },
      'ExPay' => {
        'rub' => {
          'sberbank' => 'SBERRUB',
          'tinkoff'  => 'TCSBRUB',
          ''         => 'CARDRUB'
        },
        'uzs' => {
          'humo' => 'HUMOUZS',
          '' => 'CARDUZS'
        },
        'azn' => {
          '' => 'CARDAZN'
        }
      },
      'XPayPro' => {
        'rub' => {
          'sberbank' => 'SBERBANK',
          'tinkoff'  => 'TINKOFF',
          ''         => 'BANK_ANY'
        }
      },
      'AnyMoney' => {
        'rub' => {
          ''  => 'qiwi'
        },
        'uah' => {
          ''  => 'visamc_p2p'
        }
      },
      'OkoOtc' => {
        'rub' => {
          '' => 'Все банки РФ',
          'sberbank' => 'Сбербанк',
          'tinkoff'  => 'Тинькофф',
          'qiwi'     => 'Киви'
        },
        'eur' => {
          ''  => 'EUR'
        },
        'usd' => {
          ''  => 'USD'
        },
        'azn' => {
          ''  => 'AZN'
        },
        'kzt' => {
          ''  => 'KZT'
        },
        'uzs' => {
          ''  => 'UZS'
        },
        'usdt' => {
          '' => 'USDT'
        }
      }
    }.freeze

    def initialize(adapter:, direction:)
      @adapter = adapter
      @direction = direction
    end

    def provider_bank
      sbp? ? outcome_unk : PAYWAY_TO_PROVIDER_BANK.dig(adapter_class_name, currency, send("#{direction}_payment_system").bank_name.to_s) || raise("Нету доступного банка для шлюза #{adapter_class_name}")
    end

    private

    delegate :income_currency, :income_payment_system, :outcome_currency, :outcome_payment_system, :outcome_unk, to: :order

    def order
      @order ||= adapter.respond_to?(:order) ? adapter.order : adapter.wallet_transfers.first.order_payout.order
    end

    def adapter_class_name
      @adapter_class_name ||= adapter.class.name.split('::')[1]
    end

    def currency
      @currency ||= send("#{direction}_currency").to_s.downcase.inquiry
    end

    def sbp?
      currency.rub? && outcome_unk.present?
    end
  end
end
