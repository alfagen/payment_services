# frozen_string_literal: true

module PaymentServices
  class PandaPay < Base
    autoload :Invoicer, 'payment_services/panda_pay/invoicer'
    register :invoicer, Invoicer
  end
end
