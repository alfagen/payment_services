# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'payment'
require_relative 'client'


module PaymentServices
  class QIWI
    class Importer
      CURRENCIES = {
        643 => :RUB
      }.freeze

      include Virtus.model

      attribute :wallet # Wallet
      attribute :logger

      def import_all!
        logger.info "Проверяю для кошелька #{wallet.qiwi_phone}"
        payments = get_payments

        if payments.blank?
          logger.error "#{wallet.qiwi_phone}: в payments пусто"
          return
        end

        payments.each do |data|
          catch :next do
            import_payment data
          end
        end
      end

      def get_payments
        build_client(wallet).payments['data']
      end

      def import_payment(data)
        txn_id = data['txnId']
        qiwi_payment = Payment.find_by_txn_id txn_id

        if qiwi_payment.present?
          diff = HashDiff.diff(data, qiwi_payment.data, strict: false)

          if diff.present?
            logger.info "Update #{txn_id} (#{diff}) with #{data}"
          else
            logger.info "Skip #{txn_id}"
            throw :next
          end
        else
          qiwi_payment = Payment.new
          logger.info "Create #{txn_id} with #{data}"
        end
        create_from_data qiwi_payment, data
        qiwi_payment.save!
      end

      private

      def build_client(wallet)
        raise("Wallet(#{wallet.id})#qiwi_phone is empty") if wallet.qiwi_phone.blank?

        Client.new(
          phone: Phoner::Phone.parse(wallet.qiwi_phone).to_s.tr('+', ''), # Отдаем телефон без плюса
          token: wallet.api_key.presence || raise('wallet#api_key is empty')
        )
      end

      def parse_order_public_id(comment)
        return unless comment =~ /N(\d+)/

        Regexp.last_match(1).to_i
      end

      def create_from_data(qiwi_payment, data)
        total = data['total']
        currency = Money::Currency.find! CURRENCIES[total['currency']]
        total = Money.from_amount(total['amount'], currency)
        qiwi_payment.assign_attributes(
          direction_type: data['type'],
          account: data['account'],
          status: data['status'],
          date: Time.parse(data['date']),
          txn_id: data['txnId'],
          comment: data['comment'],
          # Пока не используем
          # order_public_id: parse_order_public_id(data['comment']),
          data: data,
          total: total
        )
      end
    end
  end
end
