# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServices::Rbk::Customer, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:payment_cards) }
  end

  describe 'scopes' do
    let!(:customer1) { described_class.create!(user_id: 1, rbk_id: 'cust_1', access_token: 'token_1') }
    let!(:customer2) { described_class.create!(user_id: 2, rbk_id: 'cust_2', access_token: 'token_2') }

    it 'orders customers by id desc' do
      expect(described_class.ordered).to eq([customer2, customer1])
    end
  end

  describe '#access_token_valid?' do
    it 'returns false when access_token_expired_at is nil' do
      customer = described_class.new(access_token_expired_at: nil)
      expect(customer.access_token_valid?).to be false
    end

    it 'returns false when access_token is expired' do
      customer = described_class.new(access_token_expired_at: 1.hour.ago)
      expect(customer.access_token_valid?).to be false
    end

    it 'returns true when access_token is not expired' do
      customer = described_class.new(access_token_expired_at: 1.hour.from_now)
      expect(customer.access_token_valid?).to be true
    end
  end
end