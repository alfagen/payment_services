# frozen_string_literal: true

module PaymentServices
  class MasterProcessing < Base
    autoload :Invoicer, 'payment_services/master_processing/invoicer'
    autoload :PayoutAdapter, 'payment_services/master_processing/payout_adapter'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
