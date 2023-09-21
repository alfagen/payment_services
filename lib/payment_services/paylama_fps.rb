# frozen_string_literal: true

module PaymentServices
  class PaylamaFps < Base
    autoload :Invoicer, 'payment_services/paylama_fps/invoicer'
    register :invoicer, Invoicer
  end
end
