# frozen_string_literal: true

class PaymentServices::OneCrypto
  class Payout < ::PaymentServices::Base::CryptoPayout
    self.table_name = 'one_crypto_payouts'
  end
end
