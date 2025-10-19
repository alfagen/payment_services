# frozen_string_literal: true

require_relative '../../../lib/payment_services/base/client'

RSpec.describe PaymentServices::Base::Client do
  let(:client) { described_class.new }

  describe '#http_request' do
    let(:uri) { URI.parse('https://example.com/api') }
    let(:http) { double('Net::HTTP') }
    let(:request) { double('Request') }
    let(:response) { double('Response') }

    before do
      allow(client).to receive(:http).with(uri).and_return(http)
      allow(client).to receive(:build_request).and_return(request)
      allow(http).to receive(:request).and_return(response)
    end

    it 'sends HTTP request and returns response' do
      result = client.http_request(
        url: 'https://example.com/api',
        method: :GET,
        body: '{"test": "data"}',
        headers: { 'Content-Type' => 'application/json' }
      )

      expect(result).to eq(response)
    end
  end

  describe '#build_request' do
    let(:uri) { URI.parse('https://example.com/api') }

    context 'when method is POST' do
      it 'creates Net::HTTP::Post request' do
        request = client.build_request(uri: uri, method: :POST, body: 'test data')

        expect(request).to be_a(Net::HTTP::Post)
        expect(request.body).to eq('test data')
      end
    end

    context 'when method is GET' do
      it 'creates Net::HTTP::Get request' do
        request = client.build_request(uri: uri, method: :GET)

        expect(request).to be_a(Net::HTTP::Get)
      end
    end

    context 'when method is PATCH' do
      it 'creates Net::HTTP::Patch request' do
        request = client.build_request(uri: uri, method: :PATCH, body: 'patch data')

        expect(request).to be_a(Net::HTTP::Patch)
        expect(request.body).to eq('patch data')
      end
    end

    context 'when method is unsupported' do
      it 'raises error' do
        expect {
          client.build_request(uri: uri, method: :DELETE)
        }.to raise_error('Запрос DELETE не поддерживается!')
      end
    end
  end

  describe '#safely_parse' do
    let(:response) { double('Response') }

    context 'when response body is valid JSON' do
      before do
        allow(response).to receive(:body).and_return('{"status": "success", "data": [1, 2, 3]}')
      end

      it 'parses JSON and returns hash' do
        result = client.safely_parse(response)

        expect(result).to eq({ 'status' => 'success', 'data' => [1, 2, 3] })
      end
    end

    context 'when response body is invalid JSON' do
      before do
        allow(response).to receive(:body).and_return('invalid json')
        allow(response).to receive(:class).and_return(Net::HTTPBadRequest)
      end

      it 'returns raw body and logs warning' do
        result = client.safely_parse(response)

        expect(result).to eq('invalid json')
      end
    end

    context 'when response body is nil' do
      before do
        allow(response).to receive(:body).and_return(nil)
        allow(response).to receive(:class).and_return(Net::HTTPBadRequest)
      end

      it 'returns nil body' do
        result = client.safely_parse(response)

        expect(result).to be_nil
      end
    end
  end
end