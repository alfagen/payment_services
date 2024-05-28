# frozen_string_literal: true

module PaymentServices
  class JustPays < Base
    autoload :Invoicer, 'payment_services/just_pays/invoicer'
    register :invoicer, Invoicer
  end
end
