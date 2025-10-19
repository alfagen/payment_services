# frozen_string_literal: true

RSpec.describe PaymentServices::Rbk::PayoutDestination, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:rbk_identity) }
  end

  describe '.find_or_create_from_card_details' do
    let(:identity) { double('Identity', rbk_payout_destinations: double('PayoutDestinations')) }
    let(:tokenized_card) { { 'token' => 'token_123', 'paymentSystem' => 'visa' } }
    let(:existing_destination) { double('ExistingDestination') }

    before do
      allow(described_class).to receive(:tokenize_card!).and_return(tokenized_card)
      allow(identity.rbk_payout_destinations).to receive(:find_by).with(payment_token: 'token_123').and_return(existing_destination)
    end

    it 'returns existing destination if found' do
      result = described_class.find_or_create_from_card_details(
        number: '4111111111111111',
        name: 'John Doe',
        exp_date: '12/25',
        identity: identity
      )

      expect(result).to eq(existing_destination)
    end

    context 'when destination does not exist' do
      before do
        allow(identity.rbk_payout_destinations).to receive(:find_by).and_return(nil)
        allow(described_class).to receive(:create_destination!).and_return(double('NewDestination'))
      end

      it 'creates new destination' do
        expect(described_class).to receive(:create_destination!).with(
          identity: identity,
          tokenized_card: tokenized_card
        )

        described_class.find_or_create_from_card_details(
          number: '4111111111111111',
          name: 'John Doe',
          exp_date: '12/25',
          identity: identity
        )
      end
    end
  end

  describe '.create_destination!' do
    let(:identity) { double('Identity') }
    let(:tokenized_card) do
      {
        'token' => 'token_123',
        'paymentSystem' => 'visa',
        'bin' => '411111',
        'lastDigits' => '1111'
      }
    end
    let(:client) { double('PayoutDestinationClient') }
    let(:response) { { 'id' => 'dest_123', 'status' => 'authorized' } }

    before do
      allow(PaymentServices::Rbk::PayoutDestinationClient).to receive(:new).and_return(client)
      allow(client).to receive(:create_destination).and_return(response)
      allow(SecureRandom).to receive(:hex).with(10).and_return('abc123def456')
    end

    it 'creates destination with correct attributes' do
      destination = described_class.create_destination!(
        identity: identity,
        tokenized_card: tokenized_card
      )

      expect(destination.rbk_identity).to eq(identity)
      expect(destination.rbk_id).to eq('dest_123')
      expect(destination.public_id).to eq('abc123def456')
      expect(destination.card_brand).to eq('visa')
      expect(destination.card_bin).to eq('411111')
      expect(destination.card_suffix).to eq('1111')
      expect(destination.payment_token).to eq('token_123')
      expect(destination.rbk_status).to eq('authorized')
      expect(destination.payload).to eq(response)
    end

    it 'raises error when response has no id' do
      allow(client).to receive(:create_destination).and_return({ 'status' => 'error' })

      expect {
        described_class.create_destination!(identity: identity, tokenized_card: tokenized_card)
      }.to raise_error(described_class::Error, 'Rbk failed to create destinaion: {"status"=>"error"}')
    end
  end

  describe '.tokenize_card!' do
    let(:client) { double('PayoutDestinationClient') }
    let(:response) { { 'token' => 'token_123', 'paymentSystem' => 'visa' } }

    before do
      allow(PaymentServices::Rbk::PayoutDestinationClient).to receive(:new).and_return(client)
      allow(client).to receive(:tokenize_card).and_return(response)
    end

    it 'returns tokenized card response' do
      result = described_class.tokenize_card!(
        number: '4111111111111111',
        name: 'John Doe',
        exp_date: '12/25'
      )

      expect(result).to eq(response)
    end

    it 'raises error when tokenization fails' do
      allow(client).to receive(:tokenize_card).and_return({ 'error' => 'invalid card' })

      expect {
        described_class.tokenize_card!(
          number: '4111111111111111',
          name: 'John Doe',
          exp_date: '12/25'
        )
      }.to raise_error(described_class::Error, 'Rbk tokenization error: {"error"=>"invalid card"}')
    end
  end

  describe '#authorized?' do
    it 'returns true when status is Authorized' do
      destination = described_class.new(rbk_status: 'Authorized')
      expect(destination.authorized?).to be true
    end

    it 'returns false when status is not Authorized' do
      destination = described_class.new(rbk_status: 'Pending')
      expect(destination.authorized?).to be false
    end
  end

  describe '#refresh_info!' do
    let(:destination) { described_class.new(rbk_id: 'dest_123') }
    let(:client) { double('PayoutDestinationClient') }
    let(:response) { { 'id' => 'dest_123', 'status' => 'completed' } }

    before do
      allow(PaymentServices::Rbk::PayoutDestinationClient).to receive(:new).and_return(client)
      allow(client).to receive(:info).with(destination).and_return(response)
    end

    it 'updates destination with response data' do
      destination.refresh_info!

      expect(destination.rbk_status).to eq('completed')
      expect(destination.payload).to eq(response)
    end

    it 'does nothing when response has no status' do
      allow(client).to receive(:info).and_return({ 'id' => 'dest_123' })

      expect { destination.refresh_info! }.not_to change(destination, :rbk_status)
    end
  end
end