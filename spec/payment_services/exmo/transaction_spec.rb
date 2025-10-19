# frozen_string_literal: true

require_relative '../../../lib/payment_services/exmo/transaction'

RSpec.describe PaymentServices::Exmo::Transaction do
  describe '.build_from' do
    let(:raw_transaction) do
      {
        'status' => 'Paid',
        'extra' => {
          'txid' => 'tx_12345'
        },
        'amount' => '100.5',
        'currency' => 'BTC'
      }
    end

    it 'creates transaction from raw data' do
      transaction = described_class.build_from(raw_transaction: raw_transaction)

      expect(transaction.id).to eq('tx_12345')
      expect(transaction.provider_state).to eq('Paid')
      expect(transaction.source).to eq(raw_transaction)
    end
  end

  describe '#to_s' do
    let(:source) { { 'id' => '123', 'status' => 'Paid' } }
    let(:transaction) { described_class.new(source: source) }

    it 'returns source as string' do
      expect(transaction.to_s).to eq(source.to_s)
    end
  end

  describe '#successful?' do
    context 'when provider_state is Paid' do
      it 'returns true' do
        transaction = described_class.new(provider_state: 'Paid')
        expect(transaction.successful?).to be true
      end
    end

    context 'when provider_state is not Paid' do
      it 'returns false' do
        transaction = described_class.new(provider_state: 'Pending')
        expect(transaction.successful?).to be false
      end
    end
  end

  describe '#failed?' do
    context 'when provider_state is Cancelled' do
      it 'returns true' do
        transaction = described_class.new(provider_state: 'Cancelled')
        expect(transaction.failed?).to be true
      end
    end

    context 'when provider_state is Error' do
      it 'returns true' do
        transaction = described_class.new(provider_state: 'Error')
        expect(transaction.failed?).to be true
      end
    end

    context 'when provider_state is not in failed states' do
      it 'returns false' do
        transaction = described_class.new(provider_state: 'Paid')
        expect(transaction.failed?).to be false
      end
    end
  end
end