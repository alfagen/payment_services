# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

require_relative 'client'
# Сервис выплаты на карты с помощью РБК
#
class PaymentServices::Rbk
  class PayoutAdapter < ::PaymentServices::Base::PayoutAdapter
    # TODO: возможность передавть ID кошелька для списания
    # rubocop:disable Lint/UnusedMethodArgument
    def make_payout!(amount:, payment_card_details:, transaction_id:, destination_account:)
      # rubocop:enable Lint/UnusedMethodArgument
      raise 'Можно делать выплаты только в рублях' unless amount.currency == RUB
      raise 'Нет данных карты' unless payment_card_details.present?

      identity = Identity.current
      payout_destination = PayoutDestination.find_or_create_from_card_details(
        number: payment_card_details['number'],
        name: payment_card_details['name'],
        exp_date: payment_card_details['exp_date'],
        identity: identity
      )
      payout_destination.refresh_info!
      unless payout_destination.authorized?
        # РБК не разрешает делать выплату по неаторизованному направлению
        raise PaymentServices::UnauthorizedPayout, "РБК на разрешает вывод по направлению ##{payout_destination.id}"
      end

      Payout.create_from!(
        destination: payout_destination,
        wallet: identity.current_wallet,
        amount_cents: amount.cents
      )
    end
  end
end
