# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

module PaymentServices
  class BlockIoAdapter < Base
    autoload :PayoutAdapter, 'payment_services/block_io_adapter/payout_adapter'

    register :payout_adapter, PayoutAdapter
  end
end
