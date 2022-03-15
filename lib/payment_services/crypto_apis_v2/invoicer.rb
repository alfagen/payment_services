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
      invoice.confirmed = transaction['isConfirmed'] if transaction['isConfirmed']
      invoice.save!
    end

    def transaction_for(invoice)
      if invoice.transaction_id
        client.transaction_details(invoice.transaction_id)['data']['item']
      else
        response = client.address_transactions(invoice.address)
        raise response['error']['message'] if response.dig(:error, :message)

        response['data']['items'].find do |transaction|
          match_transaction?(transaction)
        end
      end
    end

    def match_transaction?(transaction)
      amount = parse_received_amount(transaction)
      transaction_created_at = timestamp_in_utc(transaction['timestamp'])
      invoice_created_at = expected_invoice_created_at
      return false if invoice_created_at >= transaction_created_at

      time_diff = (transaction_created_at - invoice_created_at) / 1.minute
      match_by_amount_and_time?(amount, time_diff) || match_by_txid_amount_and_time?(amount, transaction['transactionId'], time_diff)
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


[
  
{"index"=>6, "minedInBlockHash"=>"04775e1cc0f8d26d4f11677a4787a70ccef9264cb5e3a9b3acc3f3e4535ae969", "minedInBlockHeight"=>2240496, 
"recipients"=>[{"address"=>"mgeQ9fdu5cFe34abkmudd62Tw9Korp1hES", "amount"=>"0.10000000"}, {"address"=>"QeEMJJZKbP4XLG8XoM82vsoMBnUbj6cYLb", "amount"=>"11160.75914014"}], 
"senders"=>[{"address"=>"QeEMJJZKbP4XLG8XoM82vsoMBnUbj6cYLb", "amount"=>"11160.85920734"}], 
"timestamp"=>1647244633, "transactionHash"=>"2028e1f8ecdb7ac6a9b2de2d5225ba2a5abc2b268cc775a00653ea72230dacee", "transactionId"=>"2028e1f8ecdb7ac6a9b2de2d5225ba2a5abc2b268cc775a00653ea72230dacee", 
"fee"=>{"amount"=>"0.00006720", "unit"=>"LTC"}, "blockchainSpecific"=>{"locktime"=>0, "size"=>334, "vSize"=>334, "version"=>1, "vin"=>[{"addresses"=>["QeEMJJZKbP4XLG8XoM82vsoMBnUbj6cYLb"], 
"scriptSig"=>{"asm"=>"0 30440220686e19b8b2fd4ee087d45a9824112408bc7b3d58ac6b2de98de9788cf58b698e02203774be5b4ca466f13960eb55ac8ae8a778a31b3d64e8b009e5c3c1390d86e02f[ALL] 30440220287d9f5b20237ba2ed99e45a277f1e2371d4e50ddc0826eaa02be21b8c25882602207b3be65012a222e33222da03627973b51a1336b14105a273eb29062806b1a324[ALL] 52210388bb9d8787e94ad88e8fa45b12763bbfcdbcafae592b8e36f9dbfe37826d97ef21023a198a8a6e687b61f9aa6a24c787930bc75a60c09b33c01fdebb1cd9d0e5594b52ae", 
"hex"=>"004730440220686e19b8b2fd4ee087d45a9824112408bc7b3d58ac6b2de98de9788cf58b698e02203774be5b4ca466f13960eb55ac8ae8a778a31b3d64e8b009e5c3c1390d86e02f014730440220287d9f5b20237ba2ed99e45a277f1e2371d4e50ddc0826eaa02be21b8c25882602207b3be65012a222e33222da03627973b51a1336b14105a273eb29062806b1a324014752210388bb9d8787e94ad88e8fa45b12763bbfcdbcafae592b8e36f9dbfe37826d97ef21023a198a8a6e687b61f9aa6a24c787930bc75a60c09b33c01fdebb1cd9d0e5594b52ae", "type"=>"scripthash"}, 
"sequence"=>"4294967295", "txid"=>"2f0ead6aeaac249a2738601666c0f380e6f2dc6c33d39948ff22d1e4ab965632", "txinwitness"=>[], "value"=>"11160.85920734", "vout"=>1}], 
"vout"=>[{"isSpent"=>false, "scriptPubKey"=>{"addresses"=>["mgeQ9fdu5cFe34abkmudd62Tw9Korp1hES"], "asm"=>"OP_DUP OP_HASH160 0c609ed9f9526dddf43f3ccd2a4f15b91ddde7cd OP_EQUALVERIFY OP_CHECKSIG", 
"hex"=>"76a9140c609ed9f9526dddf43f3ccd2a4f15b91ddde7cd88ac", "reqSigs"=>1, "type"=>"pubkeyhash"}, "value"=>"0.10000000"}, {"isSpent"=>false, "scriptPubKey"=>{"addresses"=>["QeEMJJZKbP4XLG8XoM82vsoMBnUbj6cYLb"], 
"asm"=>"OP_HASH160 c15acd1ea3f16a6d9dd02b5dc6964dc01294ca93 OP_EQUAL", "hex"=>"a914c15acd1ea3f16a6d9dd02b5dc6964dc01294ca9387", "reqSigs"=>1, "type"=>"scripthash"}, "value"=>"11160.75914014"}]