# frozen_string_literal: true

module PaymentServices
  class Blockchair < Base
    autoload :Invoicer, 'payment_services/blockchair/invoicer'
    register :invoicer, Invoicer
  end
end
