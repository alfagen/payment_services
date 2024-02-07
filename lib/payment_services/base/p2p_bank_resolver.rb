# frozen_string_literal: true

class PaymentServices::Base
  class P2pBankResolver
    include Virtus.model

    attribute :adapter

    PAYWAY_TO_PROVIDER_BANK = {
      'PayForUH2h' => {
        'income' => {
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
        'outcome' => {
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
        }
      },
      'PaylamaP2p' => {
        'income' => {
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
        'outcome' => {
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
        }
      },
      'ExPay' => {
        'income' => {
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
        'outcome' => {
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
        }
      },
      'XPayPro' => {
        'income' => {
          'rub' => {
            'sberbank' => 'SBERBANK',
            'tinkoff'  => 'TINKOFF',
            ''         => 'BANK_ANY'
          }
        },
        'outcome' => {
          'rub' => {
            'sberbank' => 'SBERBANK',
            'tinkoff'  => 'TINKOFF',
            ''         => 'BANK_ANY'
          }
        }
      },
      'AnyMoney' => {
        'income' => {
          'rub' => {
            ''  => 'qiwi'
          },
          'uah' => {
            ''  => 'visamc_p2p'
          }
        },
        'outcome' => {
          'rub' => {
            ''  => 'qiwi'
          },
          'uah' => {
            ''  => 'visamc_p2p'
          }
        }
      },
      'OkoOtc' => {
        'income' => {
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
        },
        'outcome' => {
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
      },
      'Wallex' => {
        'income' => {
          'rub' => {
            'tinkoff'  => 'tinkoff',
            'sberbank' => 'sber',
            ''         => 'sber'
          }
        },
        'outcome' => {
          'rub' => {
            'tinkoff'  => 'Тинькофф',
            'sberbank' => 'Сбер',
            'qiwi'     => 'Киви',
            ''         => 'Все банки РФ'
          }
        }
      }
    }.freeze

    PAYWAY_TO_SBP = {
      'OkoOtc' => {
        'income'  => {},
        'outcome' => {}
      },
      'Wallex' => {
        'income' => {
          'Тинькофф Банк' => 'tinkoff',
          'Сбер' => 'sber'
        },
        'outcome' => {
          'Тинькофф Банк' => '100000000004',
          'Сбер' => '100000000111'
        }
      }
    }.freeze

    def initialize(adapter:)
      @adapter = adapter
      @direction = adapter.class.name.split('::')[2] == 'Invoicer' ? 'income' : 'outcome'
    end

    def provider_bank
      PAYWAY_TO_PROVIDER_BANK.dig(adapter_class_name, direction, currency, send("#{direction}_payment_system").bank_name.to_s) || raise("Нету доступного банка для шлюза #{adapter_class_name}")
    end

    def sbp_bank
      PAYWAY_TO_SBP.dig(adapter_class_name, direction, sbp_client_field) || sbp_client_field
    end

    def sbp?
      currency.rub? && sbp_client_field.present?
    end

    private

    delegate :income_currency, :income_payment_system, :outcome_currency, :outcome_payment_system, :income_unk, :outcome_unk, to: :order

    def order
      @order ||= direction.inquiry.income? ? adapter.order : adapter.wallet_transfers.first.order_payout.order
    end

    def adapter_class_name
      @adapter_class_name ||= adapter.class.name.split('::')[1]
    end

    def currency
      @currency ||= send("#{direction}_currency").to_s.downcase.inquiry
    end

    def sbp_client_field
      @sbp_client_field ||= send("#{direction}_unk")
    end
  end
end
