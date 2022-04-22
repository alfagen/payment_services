# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

module PaymentServices
  class BlockIo < Base
    autoload :PayoutAdapter, 'payment_services/block_io/payout_adapter'
    autoload :Invoicer, 'payment_services/block_io/invoicer'
    register :payout_adapter, PayoutAdapter
    register :invoicer, Invoicer
  end
end
