# frozen_string_literal: true

require 'base64'
require_relative 'invoice'
require_relative 'client'

class PaymentServices::MasterProcessing
  class Invoicer < ::PaymentServices::Base::Invoicer
    def create_invoice(money)
      invoice = Invoice.create!(amount: money, order_public_id: order.public_id)

      params = {
        amount: invoice.amount.to_f,
        expireAt: expire_at,
        callbackURL: order.income_payment_system.callback_url,
        comment: comment,
        clientIP: client_ip,
        paySourcesFilter: pay_source,
        cardNumber: order.income_account,
        email: order.email
      }
      params[:hsid] = generate_hsid(params)

      response = client.create_invoice(params: params)

      raise "Can't create invoice: #{response['cause']}" unless response['success']

      invoice.update!(
        deposit_id: response['externalID'],
        pay_invoice_url: response['walletList'].first
      )
    end

    def pay_invoice_url
      invoice.reload.pay_invoice_url
    end

    def invoice
      @invoice ||= Invoice.find_by!(order_public_id: order.public_id)
    end

    private

    def client
      @client ||= begin
        wallet = order.income_wallet

        Client.new(api_key: wallet.api_key, secret_key: wallet.api_secret)
      end
    end

    def expire_at
      Time.now.to_i + PreliminaryOrder::MAX_LIVE.to_i
    end

    def comment
      "Оплата по заявке: #{order.public_id}"
    end

    def client_ip
      order.user.last_login_from_ip_address
    end

    def payway
      order.income_wallet.payment_system.payway
    end

    def pay_source
      available_options = {
        'visamc' => 'card',
        'qiwi'   => 'qw'
      }
      available_options[payway] || raise "No option for payway #{payway}"
    end

    def generate_hsid(params)
      data = params.to_json
      wallet_public_key = wallet.api_key
      wallet_public_key_bin = [wallet_public_key].pack('H*')
      group = OpenSSL::PKey::EC::Group.new("prime256v1")
      public_point  = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(wallet_public_key_bin, 2))
      key = OpenSSL::PKey::EC.new(group)
      key.generate_key!
      key.public_key = public_point

      Base64.encode64(key.dsa_sign_asn1(data))
    end
  end
end
