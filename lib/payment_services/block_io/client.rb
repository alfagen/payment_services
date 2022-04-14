# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require 'block_io'

class PaymentServices::BlockIo
  class Client
    include AutoLogger
    Error = Class.new StandardError
    API_VERSION = 2

    def initialize(api_key:, pin:)
      @api_key = api_key
      @pin = pin
    end

    def make_payout(address:, amount:, nonce:)
      logger.info "---- Request payout to: #{address}, on #{amount} ----"
      begin
        prepare_response = client.prepare_transaction(amounts: amount, to_addresses: address)
        sign_response = client.create_and_sign_transaction(prepare_response)
        submit_response = client.submit_transaction(transaction_data: sign_response)
        logger.info "---- Response: #{submit_response.to_s} ----"
        submit_response
      rescue Exception => error # BlockIo uses Exceptions instead StandardError
        logger.error error.to_s
        raise Error, error.to_s
      end
    end

    def transactions(address)
      logger.info "---- Request transactions info on #{address} ----"
      begin
        transactions = client.get_transactions(type: 'sent', addresses: address)
        logger.info "---- Response: #{transactions} ----"
        transactions
      rescue Exception => error
        logger.error error.to_s
        raise Error, error.to_s
      end
    end

    private

    def client
      @client ||= BlockIo::Client.new(api_key: api_key, pin: pin, version: API_VERSION)
    end

    attr_reader :api_key, :pin
  end
end
