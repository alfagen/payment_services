# frozen_string_literal: true

module PaymentServices
  class PaylamaSbp < Base
    autoload :Invoicer, 'payment_services/paylama_sbp/invoicer'
    register :invoicer, Invoicer
  end
end
