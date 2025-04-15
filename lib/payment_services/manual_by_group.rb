# frozen_string_literal: true

module PaymentServices
  class ManualByGroup < Base
    autoload :Invoicer, 'payment_services/manual_by_group/invoicer'
    register :invoicer, Invoicer
  end
end
