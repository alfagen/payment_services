# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

module PaymentServices
  class BlockIo < Base
    autoload :Client, 'payment_services/block_io/client'
    autoload :Invoice, 'payment_services/block_io/invoice'
    autoload :Invoicer, 'payment_services/block_io/invoicer'
    autoload :Payout, 'payment_services/block_io/payout'
    autoload :PayoutAdapter, 'payment_services/block_io/payout_adapter'
    autoload :Transaction, 'payment_services/block_io/transaction'
    register :payout_adapter, PayoutAdapter
    register :invoicer, Invoicer

    def self.payout_contains_fee?
      true
    end
  end
end
