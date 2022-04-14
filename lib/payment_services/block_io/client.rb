# frozen_string_literal: true

# Copyright (c) 2020 FINFEX https://github.com/finfex

require 'block_io'

class PaymentServices::BlockIo
  class Client
    include AutoLogger
    Error = Class.new StandardError

    def initialize(api_key:, pin:)
      @api_key = api_key
      @pin = pin
    end

    def make_payout(address:, amount:, nonce:)
      blockio = BlockIo::Client.new(api_key: api_key, pin: pin, version: 2)

      begin
        prepare_response = blockio.prepare_transaction(amounts: amount, to_addresses: address)
        sign_response = blockio.create_and_sign_transaction(prepare_response)
        submit_response = blockio.submit_transaction(transaction_data: sign_response)
        logger.info "Response: #{submit_response}"
      rescue Exception => error # BlockIo uses Exceptions instead StandardError
        raise Error, error.to_s
      end
    end

    private

    attr_reader :api_key, :pin
  end
end
