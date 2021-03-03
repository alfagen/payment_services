# frozen_string_literal: true

require_relative 'clients/base_client'
require_relative 'clients/ethereum_client'
require_relative 'clients/omni_client'
require_relative 'payout_clients/base_client'
require_relative 'payout_clients/ethereum_client'
require_relative 'payout_clients/omni_client'

class Client
  BASE_CLIENT = 'BaseClient'

  CLIENTS = {
    'eth'   => 'EthereumClient',
    'etc'   => 'EthereumClient',
    'omni'  => 'OmniClient',
  }

  def initialize(currency)
    @currency = currency
  end

  def invoice
    "PaymentServices::CryptoApis::Clients::#{class_name}".constantize
  end

  def payout
    "PaymentServices::CryptoApis::PayoutClients::#{class_name}".constantize
  end

  private

  def class_name
    CLIENTS[currency] || BASE_CLIENT
  end

  attr_reader :currency
end
