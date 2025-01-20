# frozen_string_literal: true

module PaymentServices
  class FireKassa < Base
    autoload :Invoicer, 'payment_services/fire_kassa/invoicer'
    register :invoicer, Invoicer
  end
end
