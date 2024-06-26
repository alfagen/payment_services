# frozen_string_literal: true

class PaymentServices::Blockchair
  class Transaction
    include Virtus.model

    attribute :id, String
    attribute :created_at, DateTime
    attribute :blockchain, String
    attribute :source, Hash

    RIPPLE_SUCCESS_STATUS = 'tesSUCCESS'

    def self.build_from(raw_transaction:)
      new(
        id: raw_transaction[:transaction_hash],
        created_at: raw_transaction[:created_at],
        blockchain: raw_transaction[:blockchain].name,
        source: raw_transaction[:source].deep_symbolize_keys
      )
    end

    def to_s
      source.to_s
    end

    def successful?
      send("#{blockchain}_transaction_succeed?")
    end

    def sender_address
      send("#{blockchain}_sender_address")
    end

    private

    def method_missing(method_name)
      super unless method_name.end_with?('_transaction_succeed?')

      generic_transaction_succeed?
    end

    def generic_transaction_succeed?
      source.key?(:block_id) && source[:block_id].positive?
    end

    def cardano_transaction_succeed?
      source.key?(:ctbFees)
    end

    def ripple_transaction_succeed?
      source.dig(:meta, :TransactionResult) == RIPPLE_SUCCESS_STATUS
    end

    def stellar_transaction_succeed?
      source[:transaction_successful]
    end

    def eos_transaction_succeed?
      source.key?(:block_num) && source[:block_num].positive?
    end

    def bitcoin_sender_address
      source.dig(:input, :recipient)
    end

    def bitcoin_cash_sender_address
      source.dig(:input, :recipient)
    end

    def litecoin_sender_address
      source.dig(:input, :recipient)
    end

    def dogecoin_sender_address
      source.dig(:input, :recipient)
    end

    def dash_sender_address
      source.dig(:input, :recipient)
    end

    def zcash_sender_address
      source.dig(:input, :recipient)
    end

    def ethereum_sender_address
      source[:sender]
    end

    def cardano_sender_address
      source.dig(:input, :ctaAddress, :unCAddress)
    end

    def stellar_sender_address
      source[:from]
    end

    def ripple_sender_address
      source.dig(:TakerGets, :issuer)
    end

    def eos_sender_address
      source[:from]
    end

    def erc_20_sender_address
      source[:sender]
    end
  end
end
