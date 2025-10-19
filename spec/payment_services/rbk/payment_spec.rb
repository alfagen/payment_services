# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServices::Rbk::Payment, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:invoice) }
  end

  describe 'scopes' do
    let!(:payment1) { described_class.create!(amount_in_cents: 1000, rbk_id: 'pay_1', state: 'pending', order_public_id: 1) }
    let!(:payment2) { described_class.create!(amount_in_cents: 2000, rbk_id: 'pay_2', state: 'pending', order_public_id: 2) }

    it 'orders payments by id desc' do
      expect(described_class.ordered).to eq([payment2, payment1])
    end
  end

  describe 'monetize' do
    it 'monetizes amount_in_cents as amount' do
      payment = described_class.new(amount_in_cents: 1500)
      expect(payment.amount.cents).to eq(1500)
      expect(payment.amount.currency.iso_code).to eq('RUB')
    end
  end

  describe 'workflow states' do
    let(:invoice) { PaymentServices::Rbk::Invoice.create!(amount_in_cents: 1000, order_public_id: 1, state: 'pending') }
    let(:payment) { described_class.create!(amount_in_cents: 1000, rbk_id: 'pay_1', state: 'pending', order_public_id: 1, invoice: invoice) }

    before do
      # Mock invoice methods to avoid recursive calls
      allow(invoice).to receive(:pay!)
      allow(invoice).to receive(:cancel!)
    end

    it 'starts in pending state' do
      expect(payment).to be_pending
    end

    it 'transitions from pending to succeed with success!' do
      expect { payment.success! }.to change(payment, :state).from('pending').to('succeed')
    end

    it 'transitions from pending to failed with fail!' do
      expect { payment.fail! }.to change(payment, :state).from('pending').to('failed')
    end

    it 'transitions from pending to refunded with refund!' do
      expect { payment.refund! }.to change(payment, :state).from('pending').to('refunded')
    end
  end

  describe '.rbk_state_to_state' do
    let(:payment_client) { double('PaymentClient') }

    before do
      allow(PaymentServices::Rbk::PaymentClient).to receive(:const_get).and_return(payment_client)
      allow(payment_client).to receive(:const_get).and_return([])
    end

    it 'converts success states to :success' do
      allow(PaymentServices::Rbk::PaymentClient).to receive(:const_get).with('SUCCESS_STATES').and_return(['processed'])
      expect(described_class.rbk_state_to_state('processed')).to eq(:success)
    end

    it 'converts fail states to :fail' do
      allow(PaymentServices::Rbk::PaymentClient).to receive(:const_get).with('FAIL_STATES').and_return(['failed'])
      expect(described_class.rbk_state_to_state('failed')).to eq(:fail)
    end

    it 'raises error for unknown state' do
      allow(PaymentServices::Rbk::PaymentClient).to receive(:const_get).and_return([])
      expect { described_class.rbk_state_to_state('unknown') }.to raise_error('Такого статуса не существует: unknown')
    end
  end

  describe '#payment_tool_info' do
    let(:payment) { described_class.new }
    let(:payload) do
      {
        'payer' => {
          'paymentToolDetails' => {
            'cardNumberMask' => '**** **** **** 1234'
          }
        }
      }
    end

    before do
      payment.payload = payload
    end

    it 'extracts card number mask from payload' do
      expect(payment.payment_tool_info).to eq('**** **** **** 1234')
    end

    it 'returns nil when payload is empty' do
      payment.payload = {}
      expect(payment.payment_tool_info).to be_nil
    end
  end
end