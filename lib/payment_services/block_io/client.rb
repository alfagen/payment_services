# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require 'block_io'

class PaymentServices::BlockIo
  class Client < ::PaymentServices::Base::Client
    include AutoLogger
    Error = Class.new StandardError
    API_VERSION = 2
    API_URL = 'https://block.io/api/v2'

    def initialize(api_key:, pin: '')
      @api_key = api_key
      @pin = pin
    end

    def make_payout(address:, amount:, nonce:, fee_priority:)
      logger.info "---- Request payout to: #{address}, on #{amount} ----"
      transaction = prepare_transaction(params: { api_key: api_key, amounts: amount, to_addresses: address, priority: fee_priority })
      signed_transaction = block_io_client.create_and_sign_transaction(transaction)
      submit_transaction_response = block_io_client.submit_transaction(transaction_data: signed_transaction)
      logger.info "---- Response: #{submit_transaction_response.to_s} ----"
      submit_transaction_response
    rescue Exception => error # BlockIo uses Exceptions instead StandardError
      logger.error error.to_s
      raise Error, error.to_s
    end

    def prepare_transaction(params:)
      response = safely_parse(http_request(
        url: "#{API_URL}/prepare_transaction?#{params.to_query}",
        method: :GET,
        headers: build_headers
      ))
      raise Exception, response['data'] if response['status'] == 'fail'
      response
    end

    def income_transactions(address)
      transactions(address: address, type: :received)
    end

    def outcome_transactions(address)
      transactions(address: address, type: :sent)
    end

    def extract_transaction_id(response)
      response.dig('data', 'txid')
    end

    private

    def build_headers
      {}
    end

    def transactions(address:, type:)
      logger.info "---- Request transactions info on #{address} ----"
      transactions = block_io_client.get_transactions(type: type.to_s, addresses: address)
      logger.info "---- Response: #{transactions} ----"
      transactions
    rescue Exception => error
      logger.error error.to_s
      raise Error, error.to_s
    end

    def block_io_client
      @block_io_client ||= BlockIo::Client.new(api_key: api_key, pin: pin, version: API_VERSION)
    end

    attr_reader :api_key, :pin
  end
end
