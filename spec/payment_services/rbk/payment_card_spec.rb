# frozen_string_literal: true

RSpec.describe PaymentServices::Rbk::PaymentCard, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:rbk_customer) }
  end

  describe 'enums' do
    it 'defines card_type enum' do
      expect(described_class.card_types).to eq(
        'bank_card' => 0,
        'applepay' => 1,
        'googlepay' => 2
      )
    end
  end

  describe '#masked_number' do
    it 'formats the card number correctly' do
      card = described_class.new(bin: '123456', last_digits: '7890')
      expect(card.masked_number).to eq('1234 56** **** 7890')
    end

    it 'handles empty bin and last_digits' do
      card = described_class.new(bin: '', last_digits: '')
      expect(card.masked_number).to eq(' ** **** ')
    end
  end
end