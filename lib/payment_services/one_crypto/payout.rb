# frozen_string_literal: true

class PaymentServices::OneCrypto
  class Payout < ::PaymentServices::Base::CryptoPayout
    self.table_name = 'one_crypto_payouts'

    monetize :amount_cents, as: :amount

    def txid
      ''
    end
  end
end
