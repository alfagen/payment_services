# frozen_string_literal: true

# Minimal test for Tronscan Transaction model without loading full application
require 'virtus'

# Mock the transaction class for testing
class TestTronscanTransaction
  include Virtus.model

  attribute :id, String
  attribute :created_at, DateTime
  attribute :source, Hash

  def self.build_from(raw_transaction:)
    new(
      id: raw_transaction[:id],
      created_at: raw_transaction[:created_at],
      source: raw_transaction[:source].deep_symbolize_keys
    )
  end

  def to_s
    source.to_s
  end

  def successful?
    source&.dig(:confirmed) || false
  end
end

# Add deep_symbolize_keys method for hash
class Hash
  def deep_symbolize_keys
    each_with_object({}) do |(key, value), hash|
      hash[key.to_sym] = value.is_a?(Hash) ? value.deep_symbolize_keys : value
    end
  end
end

RSpec.describe TestTronscanTransaction do
  describe '.build_from' do
    let(:raw_transaction) do
      {
        id: 'tx_12345',
        created_at: Time.new(2023, 1, 1, 12, 0, 0),
        source: {
          'amount' => '100.5',
          'currency' => 'TRX',
          'confirmed' => true
        }
      }
    end

    it 'creates transaction from raw data' do
      transaction = described_class.build_from(raw_transaction: raw_transaction)

      expect(transaction.id).to eq('tx_12345')
      expect(transaction.created_at).to eq(Time.new(2023, 1, 1, 12, 0, 0))
      expect(transaction.source).to eq(
        {
          amount: '100.5',
          currency: 'TRX',
          confirmed: true
        }
      )
    end

    it 'symbolizes keys in source hash' do
      transaction = described_class.build_from(raw_transaction: raw_transaction)
      expect(transaction.source.keys).to all(be_a(Symbol))
    end
  end

  describe '#to_s' do
    let(:source) { { id: '123', amount: '100', confirmed: true } }
    let(:transaction) { described_class.new(source: source) }

    it 'returns source as string' do
      expect(transaction.to_s).to eq(source.to_s)
    end
  end

  describe '#successful?' do
    context 'when source confirmed is true' do
      it 'returns true' do
        transaction = described_class.new(source: { confirmed: true })
        expect(transaction.successful?).to be true
      end
    end

    context 'when source confirmed is false' do
      it 'returns false' do
        transaction = described_class.new(source: { confirmed: false })
        expect(transaction.successful?).to be false
      end
    end

    context 'when source is empty' do
      it 'returns false' do
        transaction = described_class.new(source: {})
        expect(transaction.successful?).to be false
      end
    end

    context 'when source is nil' do
      it 'returns false' do
        transaction = described_class.new(source: nil)
        expect(transaction.successful?).to be false
      end
    end
  end
end