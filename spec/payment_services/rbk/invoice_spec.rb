# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServices::Rbk::Invoice, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:payments).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:invoice1) { described_class.create!(amount_in_cents: 1000, order_public_id: 1, state: 'pending') }
    let!(:invoice2) { described_class.create!(amount_in_cents: 2000, order_public_id: 2, state: 'pending') }

    it 'orders invoices by id desc' do
      expect(described_class.ordered).to eq([invoice2, invoice1])
    end
  end

  describe 'monetize' do
    it 'monetizes amount_in_cents as amount' do
      invoice = described_class.new(amount_in_cents: 1500)
      expect(invoice.amount.cents).to eq(1500)
      expect(invoice.amount.currency.iso_code).to eq('RUB')
    end
  end

  describe 'workflow states' do
    let(:invoice) { described_class.create!(amount_in_cents: 1000, order_public_id: 1, state: 'pending') }

    before do
      # Mock fetch_payments! to avoid HTTP calls
      allow_any_instance_of(described_class).to receive(:fetch_payments!).and_return([])

      # Mock order method to avoid external dependencies
      order = double('Order')
      allow(order).to receive(:auto_confirm!)
      allow_any_instance_of(described_class).to receive(:order).and_return(order)
    end

    it 'starts in pending state' do
      expect(invoice).to be_pending
    end

    it 'transitions from pending to paid with pay!' do
      expect { invoice.pay! }.to change(invoice, :state).from('pending').to('paid')
    end

    it 'transitions from pending to cancelled with cancel!' do
      expect { invoice.cancel! }.to change(invoice, :state).from('pending').to('cancelled')
    end
  end
end