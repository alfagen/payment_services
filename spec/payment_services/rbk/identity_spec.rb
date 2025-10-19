# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServices::Rbk::Identity, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:rbk_wallets) }
    it { is_expected.to have_many(:rbk_payout_destinations) }
  end

  describe '.current' do
    it 'returns identity marked as current' do
      current_identity = described_class.create!(rbk_id: 'id_1', current: true)
      described_class.create!(rbk_id: 'id_2', current: false)

      expect(described_class.current).to eq(current_identity)
    end

    it 'returns nil when no current identity exists' do
      described_class.create!(rbk_id: 'id_1', current: false)

      expect(described_class.current).to be_nil
    end
  end

  describe '.create_sample!' do
    let(:identity_client) { double('IdentityClient') }
    let(:response) { { 'id' => 'identity_123', 'metadata' => 'sample' } }

    before do
      allow(PaymentServices::Rbk::IdentityClient).to receive(:new).and_return(identity_client)
      allow(identity_client).to receive(:create_sample_identity).and_return(response)
    end

    it 'creates identity with response data' do
      identity = described_class.create_sample!

      expect(identity.rbk_id).to eq('identity_123')
      expect(identity.payload).to eq(response)
    end
  end

  describe '#current_wallet' do
    let(:identity) { described_class.new(rbk_id: 'id_1') }
    let!(:current_wallet) { double('CurrentWallet') }
    let!(:other_wallet) { double('OtherWallet') }

    before do
      allow(identity).to receive(:rbk_wallets).and_return(double('Wallets'))
      allow(identity.rbk_wallets).to receive(:find_by).with(current: true).and_return(current_wallet)
    end

    it 'returns the current wallet' do
      expect(identity.current_wallet).to eq(current_wallet)
    end
  end
end