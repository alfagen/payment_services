# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServices::Rbk::Wallet, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:rbk_identity) }
  end

  describe '.create_for_identity' do
    let(:identity) { double('Identity', id: 1, rbk_wallets: double('wallets')) }
    let(:wallet_client) { double('WalletClient') }
    let(:response) { { 'id' => 'wallet_123', 'name' => 'Test Wallet' } }

    before do
      allow(PaymentServices::Rbk::WalletClient).to receive(:new).and_return(wallet_client)
      allow(wallet_client).to receive(:create_wallet).with(identity: identity).and_return(response)
    end

    it 'creates a wallet with response data' do
      expect(identity.rbk_wallets).to receive(:create!).with(
        rbk_id: 'wallet_123',
        payload: response
      )

      described_class.create_for_identity(identity)
    end
  end
end