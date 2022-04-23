# frozen_string_literal: true

class PaymentServices::Blockchair
  class Transaction
    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :source, Hash

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction[:transaction_hash],
        created_at: raw_transaction[:created_at],
        source: raw_transaction[:source].deep_symbolize_keys
      )
    end

    def to_s
      source.to_s
    end

    def successful?
      transaction_added_to_block? || source[:transaction_successful] || success_cardano_condition?
    end

    private

    def transaction_added_to_block?
      source.key?(:block_id) && source[:block_id].positive?
    end

    def success_cardano_condition?
      source.key?(:ctbFees)
    end
  end
end
