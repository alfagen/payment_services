# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentOrderSupport
  Error = Class.new StandardError
  extend ActiveSupport::Concern

  included do
    after_create :paid!, if: :success_in?
  end

  private

  def paid!
    preliminary_order = find_preliminary_order!
    logger.info "id=#{id} Привязываю оплату QIWI (#{total}) к заявке #{preliminary_order.public_id}"

    income_links.create! preliminary_order: preliminary_order, amount: total
  rescue StandardError => err
    logger.error "id=#{id} Ошибка привязки заявки: #{err}"
    Bugsnag.notify err do |b|
      b.meta_data = { qiwi_payment_id: id }
    end
    update_column :linking_error_message, err.message
  end

  # FIXME: сервис знает о заявках - это плохо
  def compatible_orders
    from = created_at.to_datetime - PreliminaryOrder::MAX_LIVE
    to = created_at.to_datetime
    PreliminaryOrder
      .where(id_ps1: compatible_payment_systems.pluck(:id))
      .by_created_at_from_to(from, to)
  end

  def compatible_payment_systems
    # FIXME: надо избавится от этой зависимости
    Gera::PaymentSystem.by_payment_service PaymentServices::QIWI.name
  end

  def find_preliminary_order!
    orders = compatible_orders.by_income_amount(total).to_a
    if orders.one?
      order = orders.first
      return order if order.income_money == total

      raise Error, "Не совпадают суммы #{order.income_money} <> #{total}"
    elsif orders.many?
      raise Error,
            "У оплаты через QIWI ##{id} (#{total}) несколько активных \
          (моложе #{PreliminaryOrder::MAX_LIVE.inspect}) предварительных заявок, \
          не знаю к какой привязаться (#{orders.pluck(:id_in_unixtime)}"
    else
      raise Error, "Пришла оплата в QIWI ##{id} на сумму #{total}, но такой предварительрной заявки нет"
    end
  end
end
