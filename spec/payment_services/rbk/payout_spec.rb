# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServices::Rbk::Payout, type: :model do

  describe 'associations' do
    it { is_expected.to belong_to(:rbk_payout_destination) }
    it { is_expected.to belong_to(:rbk_wallet) }
  end

  describe '.create_from!' do
    let(:identity) { PaymentServices::Rbk::Identity.create!(rbk_id: 'identity_123') }
    let(:destination) do
      PaymentServices::Rbk::PayoutDestination.create!(
        rbk_identity: identity,
        rbk_id: 'dest_456',
        public_id: 'dest_123',
        payment_token: 'token_123',
        card_brand: 'visa',
        card_bin: '411111',
        card_suffix: '1111',
        rbk_status: 'Authorized',
        payload: { 'test' => 'data' }
      )
    end
    let(:wallet) { PaymentServices::Rbk::Wallet.create!(rbk_identity: identity, rbk_id: 'wallet_123') }
    let(:payout_client) { double('PayoutClient') }
    let(:response) { { 'id' => 'payout_123', 'status' => 'processed' } }

    before do
      allow(PaymentServices::Rbk::PayoutClient).to receive(:new).and_return(payout_client)
      allow(payout_client).to receive(:make_payout).and_return(response)
    end

    it 'creates payout with response data' do
      payout = described_class.create_from!(
        destination: destination,
        wallet: wallet,
        amount_cents: 5000
      )

      expect(payout.rbk_id).to eq('payout_123')
      expect(payout.rbk_payout_destination).to eq(destination)
      expect(payout.rbk_wallet).to eq(wallet)
      expect(payout.amount_cents).to eq(5000)
      expect(payout.payload).to eq(response)
      expect(payout.rbk_status).to eq('processed')
    end

    it 'raises error when response status is missing' do
      allow(payout_client).to receive(:make_payout).and_return({ 'id' => 'payout_123' })

      expect {
        described_class.create_from!(
          destination: destination,
          wallet: wallet,
          amount_cents: 5000
        )
      }.to raise_error(described_class::Error, /Rbk payout error:.*id.*payout_123/)
    end
  end

  describe '#refresh_info!' do
    let(:identity) { PaymentServices::Rbk::Identity.create!(rbk_id: 'identity_123') }
    let(:destination) do
      PaymentServices::Rbk::PayoutDestination.create!(
        rbk_identity: identity,
        rbk_id: 'dest_456',
        public_id: 'dest_123',
        payment_token: 'token_123',
        card_brand: 'visa',
        card_bin: '411111',
        card_suffix: '1111',
        rbk_status: 'Authorized',
        payload: { 'test' => 'data' }
      )
    end
    let(:wallet) { PaymentServices::Rbk::Wallet.create!(rbk_identity: identity, rbk_id: 'wallet_123') }
    let(:payout) do
      described_class.create!(
        rbk_id: 'payout_123',
        rbk_payout_destination: destination,
        rbk_wallet: wallet,
        amount_cents: 5000,
        rbk_status: 'processed',
        payload: { 'test' => 'data' }
      )
    end
    let(:payout_client) { double('PayoutClient') }
    let(:response) { { 'id' => 'payout_123', 'status' => 'completed' } }

    before do
      allow(PaymentServices::Rbk::PayoutClient).to receive(:new).and_return(payout_client)
      allow(payout_client).to receive(:info).with(payout).and_return(response)
    end

    it 'updates payout with response data' do
      payout.refresh_info!

      expect(payout.rbk_status).to eq('completed')
      expect(payout.payload).to eq(response)
    end

    it 'does nothing when response is empty' do
      allow(payout_client).to receive(:info).and_return(nil)

      expect { payout.refresh_info! }.not_to change(payout, :rbk_status)
    end

    it 'does nothing when response has no status' do
      allow(payout_client).to receive(:info).and_return({ 'id' => 'payout_123' })

      expect { payout.refresh_info! }.not_to change(payout, :rbk_status)
    end
  end
end