# frozen_string_literal: true

class PaymentServices::BlockIo
  class Transaction
    delegate :confirmations, :transaction_created_at, :total_spend, to: :transaction

    def initialize(api_response:)
      @transaction = build_transaction(api_response: api_response)
    end

    private

    attr_reader :transaction

    def build_transaction(api_response:)
      Struct.new(:confirmations, :transaction_created_at, :total_spend).new(
        api_response['confirmations'], Time.at(api_response['time']).to_datetime.utc, api_response['total_amount_sent'].to_f 
      )
    end
  end
end
