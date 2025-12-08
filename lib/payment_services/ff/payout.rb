# frozen_string_literal: true


module PaymentServices
  class Ff
    class Payout < ::PaymentServices::Base::CryptoPayout
      self.table_name = 'ff_payouts'

      monetize :amount_cents, as: :amount

      def txid
        transaction_id
      end

      def update_state_by_provider!(transaction)
        update!(
          transaction_id: transaction.id,
          provider_state: transaction.status
        )

        confirm! if transaction.outcome_succeed?
        fail! if transaction.failed?
      end
    end
  end
end
