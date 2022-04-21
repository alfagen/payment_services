# frozen_string_literal: true

class PaymentServices::Blockchair
  class Transaction
    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :source, String

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction[:transaction_hash],
        created_at: raw_transaction[:created_at],
        source: raw_transaction
      )
    end

    def to_s
      attributes.to_s
    end

    def successful?
      transaction_added_to_block? || source['transaction_successful']
    end

    private

    def transaction_added_to_block?
      source.key?('block_id') ? source['block_id'] > 0 : true
    end
  end
end
