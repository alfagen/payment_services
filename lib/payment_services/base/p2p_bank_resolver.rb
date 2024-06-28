# frozen_string_literal: true

class PaymentServices::Base::P2pBankResolver
  include Virtus.model

  attribute :adapter

  PAYWAY_TO_CARD_BANK = {
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
          'raiffeisen' => 'RAIFFEISENBANK',
          ''         => 'BANK_ANY'
        }
      },
      'outcome' => {
        'rub' => {
          'sberbank' => 'SBERBANK',
          'tinkoff'  => 'TINKOFF',
          'raiffeisen' => 'RAIFFEISENBANK',
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
    },
    'MerchantAlikassa' => {
      'income' => {
        'rub' => {
          'sberbank'   => 'sberbank',
          'raiffeisen' => 'raiffeisen',
          ''           => 'sberbank'
        }
      },
      'outcome' => {
        'sberbank'   => 'sberbank',
        'raiffeisen' => 'raiffeisen',
        ''           => 'sberbank'
      }
    },
    'YourPayments' => {
      'income' => {
        'rub' => {
          'tinkoff'    => 'tinkoff',
          'sberbank'   => 'sberbank',
          'raiffeisen' => 'raiffeisen',
          ''           => 'tinkoff'
        }
      },
      'outcome' => {
        'rub' => {
          'tinkoff'    => 'tinkoff',
          'sberbank'   => 'sberbank',
          'raiffeisen' => 'raiffeisen',
          ''           => 'tinkoff'
        }
      }
    },
    'Bridgex' => {
      'income' => {
        'rub' => {
          'sberbank'   => 'Sberbank',
          'tinkoff'    => 'Tinkoff',
          'raiffeisen' => 'Raiffeisen',
          ''           => 'unused_param'
        }
      },
      'outcome' => {}
    },
    'Transfera' => {
      'income' => {
        'rub' => {
          'sberbank'   => 'Sber',
          'raiffeisen' => 'Raif',
          ''           => 'Mir'
        }
      },
      'outcome' => {}
    },
    'Paycraft' => {
      'income' => {
        'rub' => {
          'sberbank'   => 'Сбербанк',
          'tinkoff'    => 'Тинькофф'
        }
      },
      'outcome' => {}
    }
  }.freeze

  PAYWAY_TO_SBP_BANK = {
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
        'Сбер' => '100000000111',
        'Банк ВТБ' => '100000000005',
        'АЛЬФА-БАНК' => '100000000008',
        'Райффайзенбанк' => '100000000007',
        'Банк ОТКРЫТИЕ' => '100000000015',
        'Газпромбанк' => '100000000001',
        'Промсвязьбанк' => '100000000010',
        'Хоум кредит' => '100000000024',
        'Россельхозбанк' => '100000000020',
        'Совкомбанк' => '100000000013',
        'Точка ФК Открытие' => '100000000065'
      }
    },
    'YourPayments' => {
      'income' => {
        'Тинькофф Банк' => 'tinkoff_sbp',
        'Сбер' => 'sberbank_sbp',
        'Банк ВТБ' => 'vtb_sbp',
        'АЛЬФА-БАНК' => 'alfabank_sbp',
        'Райффайзенбанк' => 'raiffeisen_sbp',
        'Банк ОТКРЫТИЕ' => 'tochka_sbp',
        'Газпромбанк' => 'gazprom_sbp',
        'Промсвязьбанк' => 'promsvyazbank_sbp',
        'Хоум кредит' => 'home_sbp',
        'Россельхозбанк' => 'rosselhozbank_sbp',
        'Совкомбанк' => 'sovcombank_sbp',
        'Точка ФК Открытие' => 'tochka_sbp'
      },
      'outcome' => {
        'Тинькофф Банк' => 'tinkoff_sbp',
        'Сбер' => 'sberbank_sbp',
        'Банк ВТБ' => 'vtb_sbp',
        'АЛЬФА-БАНК' => 'alfabank_sbp',
        'Райффайзенбанк' => 'raiffeisen_sbp',
        'Банк ОТКРЫТИЕ' => 'tochka_sbp',
        'Газпромбанк' => 'gazprom_sbp',
        'Промсвязьбанк' => 'promsvyazbank_sbp',
        'Хоум кредит' => 'home_sbp',
        'Россельхозбанк' => 'rosselhozbank_sbp',
        'Совкомбанк' => 'sovcombank_sbp',
        'Точка ФК Открытие' => 'tochka_sbp'
      }
    },
    'Bridgex' => {
      'income' => {
        'Тинькофф Банк' => 'tinkoff',
        'Сбер' => 'sberbank',
        'Райффайзенбанк' => 'Raiffeisen'
      },
      'outcome' => {}
    },
    'MerchantAlikassa' => {
      'income' => {},
      'outcome' => {
        'Тинькофф Банк' => '100000000004',
        'Сбер' => '100000000111',
        'Банк ВТБ' => '100000000005',
        'АЛЬФА-БАНК' => '100000000008',
        'Райффайзенбанк' => '100000000007',
        'Банк ОТКРЫТИЕ' => '100000000015',
        'Газпромбанк' => '100000000001',
        'Промсвязьбанк' => '100000000010',
        'Хоум кредит' => '100000000024',
        'Россельхозбанк' => '100000000020',
        'Совкомбанк' => '100000000013',
        'Точка ФК Открытие' => '100000000065'
      }
    },
    'Paycraft' => {
      'income' => {
        'Тинькофф Банк' => '100000000004',
        'Сбер' => '100000000111',
        'Банк ВТБ' => '100000000005',
        'АЛЬФА-БАНК' => '100000000008',
        'Райффайзенбанк' => '100000000007',
        'Банк ОТКРЫТИЕ' => '100000000015',
        'Газпромбанк' => '100000000001',
        'Промсвязьбанк' => '100000000010',
        'Хоум кредит' => '100000000024',
        'Россельхозбанк' => '100000000020',
        'Совкомбанк' => '100000000013',
        'Точка ФК Открытие' => '100000000065'
      },
      'outcome' => {}
    }
  }.freeze

  def initialize(adapter:)
    @adapter = adapter
    @direction = adapter.class.name.demodulize == 'Invoicer' ? 'income' : 'outcome'
  end

  def card_bank
    PAYWAY_TO_CARD_BANK.dig(adapter_class_name, direction, currency, send("#{direction}_payment_system").bank_name.to_s) || raise("Нету доступного банка для шлюза #{adapter_class_name}")
  end

  def sbp_bank
    PAYWAY_TO_SBP_BANK.dig(adapter_class_name, direction, sbp_client_field) || 
    PAYWAY_TO_SBP_BANK.dig(adapter_class_name, direction, sbp_client_field_new)
  end

  def sbp?
    @sbp ||= currency.rub? && sbp_checkbox
  end

  private

  attr_reader :direction

  delegate :income_sbp, to: :income_payment_system
  delegate :outcome_sbp, to: :outcome_payment_system
  delegate :income_currency, :income_payment_system, :outcome_currency, :outcome_payment_system, :income_unk, :outcome_unk, :income_bank, :outcome_bank, to: :order

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

  def sbp_client_field_new
    @sbp_client_field ||= send("#{direction}_bank")
  end

  def sbp_checkbox
    @sbp_checkbox ||= send("#{direction}_sbp")
  end
end
