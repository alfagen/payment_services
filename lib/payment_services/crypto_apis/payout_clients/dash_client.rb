# frozen_string_literal: true

require_relative '../clients/dash_client'

class PaymentServices::CryptoApis
  module PayoutClients
    class DashClient < PaymentServices::CryptoApis::Clients::DashClient
    end
  end
end
