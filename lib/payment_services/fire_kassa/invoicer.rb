# frozen_string_literal: true

require_relative 'invoice'
require_relative 'client'

class PaymentServices::FireKassa
  class Invoicer < ::PaymentServices::Base::Invoicer
    Error = Class.new StandardError
    DEFAULT_CARD = 'sber'

    def prepare_invoice_and_get_wallet!(currency:, token_network:)
      create_invoice!
      response = sbp? ? client.create_sbp_invoice(params: invoice_params) : client.create_card_invoice(params: invoice_params)
      raise Error, "Can't create invoice: #{response['message']}" if response['message']

      invoice.update!(deposit_id: response['id'])
      PaymentServices::Base::Wallet.new(
        address: response['card_number'] || format_phone_number(response['account']),
        name: [response['first_name'].capitalize, response['last_name'].capitalize].join(' '),
        memo: response['bank'].capitalize
      )
    end

    def create_invoice(money)
      invoice
    end

    def async_invoice_state_updater?
      true
    end

    def update_invoice_state!
      transaction = client.transaction(transaction_id: invoice.deposit_id)
      invoice.update_state_by_provider(transaction['status'])
    end

    def invoice
      @invoice ||= Invoice.find_by(order_public_id: order.public_id)
    end

    private

    delegate :card_bank, :sbp_bank, :sbp?, to: :bank_resolver

    def create_invoice!
      Invoice.create!(amount: order.calculated_income_money, order_public_id: order.public_id)
    end

    def invoice_params
      params = {
        account: order.income_account,
        order_id: order.public_id.to_s,
        site_account: DEFAULT_CARD,
        amount: invoice.amount.to_f.to_s,
        comment: "Order ##{order.public_id.to_s}",
        ext_txn: order.public_id.to_s,
        ext_date: order.created_at.iso8601
      }
      params[:ext_last_name] = order.user.aml_client.surname if order&.user&.aml_client&.surname.present?
      params[:ext_first_name] = order.user.aml_client.first_name if order&.user&.aml_client&.first_name.present?
      params[:ext_email] = order.user_email if order&.user&.email.present?
      params[:ext_ip] = order.remote_ip if order.remote_ip.present?
      params[:ext_user_agent] = order.user.user_agent if order&.user&.user_agent.present?
      params[:ext_photo] = CardVerification.find_by(order_public_id: order.public_id).image.url if CardVerification.find_by(order_public_id: order.public_id)&.image&.url.present?
      params[:bank_id] = sbp_bank if sbp?
      params
    end

    def bank_resolver
      @bank_resolver ||= PaymentServices::Base::P2pBankResolver.new(adapter: self)
    end

    def client
      @client ||= Client.new(api_key: api_key)
    end

    def format_phone_number(account)
      "+7 (#{account[0..2]}) #{account[3..5]}-#{account[6..7]}-#{account[8..9]}"
    end
  end
end
