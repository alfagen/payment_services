# frozen_string_literal: true

require_relative 'payout'
require_relative 'payout_client'

class PaymentServices::CryptoApis
  class PayoutAdapter
    attribute :order

    # payout_wallets - массив из кошельков из уже просчитанными суммами
    def create_payout(amount_cents, payout_wallets, destination_address, fee, wifs)
      payout = Payout.new(amount_cents: amount_cents, destination_address: destination_address, wifs: wifs, fee: fee)
      payout.payout_wallets = payout_wallets
      payout.save!
    end

    def make_payout!
      response = client.make_payout(query: payout.api_query)
      return response[:meta][:error][:message] if response.dig(:meta, :error, :message)

      payout.pay!(txid: response[:payload][:txid])
    end

    def refresh_status!
      return if payout.pending?

      transaction = client.transaction_details(txid: payout.txid)[:payload]
      payout.update!(confirmation: transaction[:confirmations])

      payout.confirmed! if payout.complete_payment?
    end

    def payout
      @payout ||= Payout.find_by(order_public_id: order.public_id)
    end

    private

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        PayoutClient.new(api_key: wallet.api_key)
      end
    end
  end
end
