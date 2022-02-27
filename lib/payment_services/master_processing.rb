# frozen_string_literal: true

module PaymentServices
  class MasterProcessing < Base
    autoload :Invoicer, 'payment_services/master_processing/invoicer'
    register :invoicer, Invoicer
  end
end
