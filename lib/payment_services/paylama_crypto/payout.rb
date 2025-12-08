# frozen_string_literal: true

module PaymentServices
  class PaylamaCrypto
    class Payout < ::PaymentServices::Paylama::Payout
      def update_state_by_transaction(transaction)
        update!(
          provider_state: transaction.status,
          fee: transaction.fee  
        )

        confirm! if transaction.succeed?
        fail! if transaction.failed?
      end
    end
  end
end
