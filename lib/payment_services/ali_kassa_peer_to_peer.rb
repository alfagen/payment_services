# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex

module PaymentServices
  class AliKassaPeerToPeer < Base
    autoload :Invoice, 'payment_services/ali_kassa_peer_to_peer/invoice'
    autoload :Invoicer, 'payment_services/ali_kassa_peer_to_peer/invoicer'
    register :invoicer, Invoicer
  end
end
