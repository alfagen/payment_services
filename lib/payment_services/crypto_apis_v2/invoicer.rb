# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::CryptoApisV2
  class Invoicer < ::PaymentServices::Base::Invoicer
    TRANSACTION_TIME_THRESHOLD = 30.minutes
    ETC_TIME_THRESHOLD = 20.seconds
    PARTNERS_RECEIVED_AMOUNT_DELTA = 0.000001

    def create_invoice(money)
      Invoice.create!(amount: money, order_public_id: order.public_id, address: order.income_account_emoney)
    end

    def update_invoice_state!
      transaction = transaction_for(invoice)
      return if transaction.nil?

      invoice.has_transaction! if invoice.pending?

      update_invoice_details(invoice: invoice, transaction: transaction)
      invoice.pay!(payload: transaction) if invoice.confirmed?
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    def async_invoice_state_updater?
      true
    end

    private

    def update_invoice_details(invoice:, transaction:)
      invoice.transaction_created_at ||= timestamp_in_utc(transaction['timestamp'])
      invoice.transaction_id ||= transaction['transactionId']
      invoice.confirmed = transaction['isConfirmed']
      invoice.save!
    end

    def transaction_for(invoice)
      if invoice.transaction_id
        client.transaction_details(invoice.transaction_id)['data']['item']
      else
        response = client.address_transactions(invoice.address)
        raise response response['error']['message'] if response.dig(:error, :message)

        response['data']['items'].find do |transaction|
          match_transaction?(transaction)
        end if response['data']
      end
    end

    def match_transaction?(transaction)
      amount = parse_received_amount(transaction)
      transaction_created_at = timestamp_in_utc(transaction[:timestamp])
      invoice_created_at = expected_invoice_created_at
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / 1.minute
      match_by_amount_and_time?(amount, time_diff) || match_by_txid_amount_and_time?(amount, transaction[:txid], time_diff)
    end

    def match_by_amount_and_time?(amount, time_diff)
      match_amount?(amount) && match_transaction_time_threshold?(time_diff)
    end
    
    def match_by_txid_amount_and_time?(amount, txid, time_diff)
      invoice.possible_transaction_id.present? &&
        match_txid?(txid) &&
        match_amount_with_delta?(amount) &&
        match_transaction_time_threshold?(time_diff)
    end

    def match_amount?(received_amount)
      received_amount.to_d == invoice.amount.to_d
    end

    def match_amount_with_delta?(received_amount)
      amount_diff = received_amount.to_d - invoice.amount.to_d
      amount_diff >= 0 && amount_diff <= PARTNERS_RECEIVED_AMOUNT_DELTA
    end

    def match_transaction_time_threshold?(time_diff)
      time_diff.round.minutes < TRANSACTION_TIME_THRESHOLD
    end

    def match_txid?(txid)
      txid == invoice.possible_transaction_id
    end

    def parse_received_amount(transaction)
      transaction['recipients'].find { |recipient| recipient['address'] == invoice.address }['amount']
    end

    def timestamp_in_utc(timestamp)
      DateTime.strptime(timestamp.to_s,'%s').utc
    end

    def expected_invoice_created_at
      invoice_created_at = invoice.created_at.utc
      invoice_created_at -= ETC_TIME_THRESHOLD if invoice.amount_currency == 'ETC'
      invoice_created_at
    end

    def client
      @client ||= begin
        wallet = order.income_wallet
        api_key = wallet.api_key.presence || wallet.parent&.api_key
        currency = wallet.currency.to_s.downcase

        Client.new(api_key: api_key, currency: currency)
      end
    end
  end
end


{
    "apiVersion": "2.0.0",
    "requestId": "601c1710034ed6d407996b30",
    "context": "You can add any text here",
    "data": {
        "limit": 50,
        "offset": 0,
        "total": 100,
        "items": [
            {
                "index": 1,
                "minedInBlockHash": "00000000407f119ecb74b44229228910400aaeb9f4e3b9869955b85a53e9b7db",
                "minedInBlockHeight": 1903849,
                "recipients": [
                    {
                        "address": "2MzakdGTEp8SMWEHKwKM4HYv6uNCBXtHpkV",
                        "amount": "0.000144"
                    }
                ],
                "senders": [
                    {
                        "address": "2N5PcdirZUzKF9bWuGdugNuzcQrCbBudxv1",
                        "amount": "0.00873472"
                    }
                ],
                "timestamp": 1582202940,
                "transactionHash": "1ec73b0f61359927d02376b35993b756b1097cb9a857bec23da4c98c4977d2b2",
                "transactionId": "4b66461bf88b61e1e4326356534c135129defb504c7acb2fd6c92697d79eb250",
                "fee": {
                    "amount": "0.00016932",
                    "unit": "BTC"
                },
                "blockchainSpecific": {
                    "locktime": 1781965,
                    "size": 125,
                    "vSize": 166,
                    "version": 2,
                    "vin": [
                        {
                            "addresses": [
                                "2N5PcdirZUzKF9bWuGdugNuzcQrCbBudxv1"
                            ],
                            "coinbase": "0399991d20706f6f6c2e656e6a6f79626f646965732e636f6d20393963336532346234374747a53e994c4a000001",
                            "scriptSig": {
                                "asm": "0014daaf6d5cb86befe42df851a4d1df052e663754c1",
                                "hex": "160014daaf6d5cb86befe42df851a4d1df052e663754c1",
                                "type": "scripthash"
                            },
                            "sequence": "4294967295",
                            "txid": "caee978cae255bbe303ac86152679e46113a8b12925aa3afaa312d89d11ccbf8",
                            "txinwitness": [
                                "3045022100c11ea5740bcd69f0f68a4914279838014d28923134d18e05c5a5486dfd06cc8c02200dadccec3f07bed0d1040f9e5a155efa5fdd40fc91f92342578d26848da4c6b901"
                            ],
                            "value": "0.00873472",
                            "vout": 1
                        }
                    ],
                    "vout": [
                        {
                            "isSpent": true,
                            "scriptPubKey": {
                                "addresses": [
                                    "2N5PcdirZUzKF9bWuGdugNuzcQrCbBudxv1"
                                ],
                                "asm": "OP_HASH160 ca94af32587de4e5006685ffffc65a818ccd3fbc OP_EQUAL",
                                "hex": "a914507a5bd8cac1d9efdf4c0a4bfacb3e0abb4f8d1587",
                                "reqSigs": 1,
                                "type": "scripthash"
                            },
                            "value": "0.000144"
                        }
                    ]
                }
            }
        ]
    }
}