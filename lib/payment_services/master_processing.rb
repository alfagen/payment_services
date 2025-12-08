# frozen_string_literal: true

module PaymentServices
  class MasterProcessing < Base
    autoload :Client, 'payment_services/master_processing/client'
    autoload :Invoice, 'payment_services/master_processing/invoice'
    autoload :Invoicer, 'payment_services/master_processing/invoicer'
    autoload :Payout, 'payment_services/master_processing/payout'
    autoload :PayoutAdapter, 'payment_services/master_processing/payout_adapter'
    autoload :Response, 'payment_services/master_processing/response'
    register :invoicer, Invoicer
    register :payout_adapter, PayoutAdapter
  end
end
