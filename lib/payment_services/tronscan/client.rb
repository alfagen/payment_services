# frozen_string_literal: true

class PaymentServices::Tronscan::Client < ::PaymentServices::Base::Client
  API_URL = 'https://apilist.tronscanapi.com/api'
  CURRENCY_TO_ENDPOINT = {
    'trx'  => 'trx',
    'usdt' => 'trc20'
  }.freeze

  def initialize(api_key:, currency:)
    @api_key  = api_key
    @currency = currency
  end

  def transactions(address:, invoice_created_at:)
    params = { address: address, start_timestamp: invoice_created_at.to_i }.to_query
    safely_parse(http_request(
      url: "#{API_URL}/transfer/#{endpoint}?#{params}",
      method: :GET,
      headers: build_headers
    ))['data']
  end

  private

  attr_reader :api_key, :currency

  def build_headers
    {
      'TRON-PRO-API-KEY' => api_key
    }
  end

  def endpoint
    CURRENCY_TO_ENDPOINT[currency] || raise("#{currency} is not supported")
  end
end
