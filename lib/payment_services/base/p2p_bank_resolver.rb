# frozen_string_literal: true

class PaymentServices::Base
  class P2pBankResolver
    include Virtus.model

    attribute :invoicer

    PAYWAY_TO_PROVIDER_BANK = {
      'PaymentServices::PayForUH2h::Invoicer' => {
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
      'PaymentServices::PaylamaP2p::Invoicer' => {
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
      'PaymentServices::ExPay::Invoicer' => {
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
    }.freeze

    def initialize(invoicer:)
      @invoicer = invoicer
    end

    def provider_bank
      PAYWAY_TO_PROVIDER_BANK.dig(invoicer_class_name, income_currency.to_s.downcase, bank_name.to_s) || raise("Нету доступного банка для шлюза #{invoicer_class_name}")
    end

    private

    delegate :bank_name, to: :income_payment_system
    delegate :income_currency, :income_payment_system, to: :order
    delegate :order, to: :invoicer

    def invoicer_class_name
      @invoicer_class_name ||= invoicer.class.name
    end
  end
end
