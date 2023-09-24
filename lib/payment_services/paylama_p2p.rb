# frozen_string_literal: true

module PaymentServices
  class PaylamaP2p < Base
    autoload :Invoicer, 'payment_services/paylama_p2p/invoicer'
    register :invoicer, Invoicer
  end
end
