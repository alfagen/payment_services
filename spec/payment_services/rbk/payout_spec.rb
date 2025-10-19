# frozen_string_literal: true

RSpec.describe PaymentServices::Rbk::Payout, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:rbk_payout_destination) }
    it { is_expected.to belong_to(:rbk_wallet) }
  end

  describe '.create_from!' do
    let(:destination) { double('PayoutDestination') }
    let(:wallet) { double('Wallet') }
    let(:payout_client) { double('PayoutClient') }
    let(:response) { { 'id' => 'payout_123', 'status' => 'processed' } }

    before do
      allow(PaymentServices::Rbk::PayoutClient).to receive(:new).and_return(payout_client)
      allow(payout_client).to receive(:make_payout).and_return(response)
    end

    it 'creates payout with response data' do
      payout = described_class.create_from!(
        destinaion: destination,
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
          destinaion: destination,
          wallet: wallet,
          amount_cents: 5000
        )
      }.to raise_error(described_class::Error, 'Rbk payout error: {"id"=>"payout_123"}')
    end
  end

  describe '#refresh_info!' do
    let(:payout) { described_class.new(rbk_id: 'payout_123') }
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